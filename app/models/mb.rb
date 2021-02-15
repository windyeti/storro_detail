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
        vendorcode: pr.xpath("vendorCode").text,
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
      product_sku = "МБ#{mb.vendorcode.sub(/N/, '-')}"
      product = Product.find_by(sku: product_sku)
      if product
        product.productid_provider = mb.id
        product.provider_id = 1
        product.save
        mb.productid_product = product.id
        mb.save
      end
    end
  end

  def self.syncronaize
    Mb.find_each(batch_size: 1000) do |provider_product|

      insales_product = Product.find(provider_product.productid_product) rescue nil

      if insales_product
        # если товар: соотнесен с поставщиком; есть у поставщика; и его количество более 3
        # то visible поменяется ниже на true
        insales_product.visible = false

        new_insales_price = (insales_product.price / insales_product.provider_price) * provider_product.price.to_f

        # с округлением до целого по правилу 0.5
        insales_product.price = new_insales_price.round
        insales_product.provider_price = provider_product.price.to_f

        # store лишняя сущность, так как в приложении остаток храниться в quantity
        # store на входе записывается в quantity
        # а на выходе quantity в store

        # количество Товара у Поставщика должнобыть 3 и более
        provider_product_quantity = provider_product.quantity

        insales_product.quantity = provider_product_quantity >= 3 ? provider_product.quantity : 0

        insales_product.visible = true if provider_product_quantity >= 3

        insales_product.save
      end
    end
  end

  def self.import_linking_syncronaize
    self.import
    self.linking
    self.syncronaize
    Product.create_csv
  end

  def self.unlinking_to_csv
    file = "#{Rails.root}/public/mbs/mbs_unlinking.csv"
    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    products = Mb.where(productid_product: nil).order(:id)

    CSV.open("#{Rails.root}/public/mbs/mbs_unlinking.csv", "wb") do |writer|
      headers = [ "ID", "Available", "Остаток", "Ссылка", "Фото", "Цена", "Валюта", "Категория", "Название", "Описание", "Код произв.", "Бар-код", "Страна", "Бренд", "Параметры", "Актуальность", "ID в табл. Товаров" ]

      writer << headers
      products.each do |pr|
        fid = pr[:fid]
        available = pr[:available]
        quantity = pr[:quantity]
        link = pr[:link]
        pict = pr[:pict]
        price = pr[:price]
        currencyid = pr[:currencyid]
        cat = pr[:cat]
        title = pr[:title]
        desc = pr[:desc]
        vendorcode = pr[:vendorcode]
        barcode = pr[:barcode]
        country = pr[:country]
        brend = pr[:brend]
        param = pr[:param]
        check = pr[:check]
        productid_product = pr[:productid_product]

        writer << [
          fid,
          available,
          quantity,
          link,
          pict,
          price,
          currencyid,
          cat,
          title,
          desc,
          vendorcode,
          barcode,
          country,
          brend,
          param,
          check,
          productid_product
        ]
      end
    end #CSV.open
  end
end

"fid"
"available"
"quantity"
"link"
"pict"
"price"
"currencyid"
"cat"
"title"
"desc"
"vendorcode"
"barcode"
"country"
"brend"
"param"
"check"
"productid_product"
