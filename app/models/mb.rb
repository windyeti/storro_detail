class Mb < ApplicationRecord

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  def self.import
    puts '=====>>>> СТАРТ YML '+Time.now.to_s
    uri = "http://export.mb-catalog.ru/users/export/yml_download_new.php?email=aichurkin@storro.ru"
    response = RestClient.get uri, :accept => :xml, :content_type => "application/xml"
    data = Nokogiri::XML(response)
    mypr = data.xpath("//offer")

    if mypr.size == 0
      File.open("#{Rails.root}/public/errors_update.txt", 'a') do |f|
        f.write "!!! [#{Time.now}] Цены и Остатки не обновились у поставщика МБ\n"
      end
      return
    end

    # 1. перед накатыванием обновления товаров у поставщика
    # все существующим ставим check = false
    # чтобы не удалять товары поставщика, так как их id
    # связан с товарами Product
    # 2. обнуляем остатки у всех -- те, что будут присутствовать
    # в списке добавят себе цену
    Mb.all.find_each(batch_size: 1000) do |mb|
      mb.check = false
      mb.quantity = 0
      mb.save
    end

    mypr.each do |pr|

      data = {
        fid: pr["id"],
        available: pr["available"] == 'true' ? true : false,
        quantity: pr["ostatok"],
        link: pr.xpath("url").text,
        pict: pr.xpath("picture").map(&:text).join(''),
        price: pr.xpath("price").text,
        currencyid: pr.xpath("currencyId").text,
        cat: pr.xpath("categoryId").text,
        title: pr.xpath("name").text,
        desc: pr.xpath("description").text,
        vendorcode: pr.xpath("vendorCode").text.strip,
        barcode: pr.xpath("barcode").text,
        country: pr.xpath("country").text,
        brend: pr.xpath("brend").text,
        param: pr.xpath("param").text,
        check: true
      }

      tov = Mb.find_by_fid(data[:fid])

      if tov.present?
        tov.update(data)
      else
        Mb.create(data)
      end


    end
    puts '=====>>>> FINISH YML '+Time.now.to_s
  end

  def self.linking
    Mb.find_each(batch_size: 1000) do |mb|
      product_sku = "МБ#{mb.vendorcode.gsub(/N/, '-')}"
      products = Product.where(sku: product_sku)
      products.each do |product|
        product.productid_provider = mb.id
        product.provider_id = 1
        product.save
        mb.productid_product = product.id
        mb.save
      end
    end
  end

  def self.syncronaize
    Product.find_each(batch_size: 1000) do |product|
      if product.sku&.match(/^МБ/)
        product.update(quantity: 0)
      end
    end

    Mb.find_each(batch_size: 1000) do |provider_product|

       Product.where(productid_provider: provider_product.id).where(provider_id: 1).each do |insales_product|
        # если товар: соотнесен с поставщиком; есть у поставщика; и его количество более 3
        # то visible поменяется ниже на true
        insales_product.visible = false

        if insales_product.komplekt.present?
          provider_product_price = provider_product.price.to_f * insales_product.komplekt
          provider_product_quantity = (provider_product.quantity / insales_product.komplekt).floor
        else
          provider_product_price = provider_product.price.to_f
          provider_product_quantity = provider_product.quantity
        end

        min_quantity_for_yandex = 3

        new_insales_price = (insales_product.price / insales_product.provider_price) * provider_product_price

        # с округлением до целого по правилу 0.5
        # меняем цену продажи только если цена провайдера не ноль
        insales_product.price = new_insales_price.round if insales_product.provider_price != 0 && !insales_product.provider_price.nil?
        insales_product.provider_price = provider_product_price

        # store лишняя сущность, так как в приложении остаток храниться в quantity
        # store на входе записывается в quantity
        # а на выходе quantity в store

        # количество Товара у Поставщика должнобыть 3 и более

        if insales_product.komplekt.present?
          if insales_product.komplekt * provider_product_quantity == 2000
            insales_product.quantity = 2000
          else
            insales_product.quantity = provider_product_quantity >= min_quantity_for_yandex ? provider_product_quantity : 0
          end
        else
          insales_product.quantity = provider_product_quantity >= min_quantity_for_yandex ? provider_product_quantity : 0
        end

        insales_product.visible = true if provider_product_quantity >= min_quantity_for_yandex

        insales_product.save
      end

    end
  end

  def self.import_linking_syncronaize
    self.import
    self.linking
    self.syncronaize
  end

  def self.unlinking_to_xls
    file = "#{Rails.root}/public/mbs_unlinking.xls"

    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'МБ незалинкованные')
    sheet.row(0).push("ID", "ID в таблице Товаров", "Название", "Актуальность", "Остаток", "Цена", "Описание", "Код производителя", "Barcode", "Страна", "Бренд", "Параметры", "Картинки")

    products = Mb.where(productid_product: nil).order(:id)

    products.each_with_index do |pr, index|
      id = pr[:id]
      productid_product = pr[:productid_product]
      title = pr[:title]
      check = pr[:check]
      quantity = pr[:quantity]
      price = pr[:price]
      desc = pr[:desc]
      vendorcode = pr[:vendorcode]
      barcode = pr[:barcode]
      country = pr[:country]
      brend = pr[:brend]
      param = pr[:param]
      pict = pr[:pict]

      sheet.row(index + 1).push(
        id,
        productid_product,
        title,
        check ? 'был' : 'не был',
        quantity,
        price,
        desc,
        vendorcode,
        barcode,
        country,
        param,
        brend,
        pict
      )
    end

    book.write file
  end
end
