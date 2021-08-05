require 'net/sftp'
require 'net/ssh'

class Vl < ApplicationRecord

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  def self.import
    puts "====>>>> START Import Vl === #{Time.now}"

    file_path = "#{Rails.root}/public/vl_import.xml"

    check = File.file?(file_path)
    if check.present?
      File.delete(file_path)
    end

    begin
      Net::SFTP.start('206.189.105.238', 'vl', password: '85uttbtf') do |sftp|
        sftp.download!("/home/vl/ftp/files/Price.xml", "#{Rails.public_path}/vl_import.xml")
      end
    rescue
      return
    end

    file = File.open(file_path)

    doc = Nokogiri::XML(file)

    doc_products = doc.xpath("//items")

    return if doc_products.count == 0

    Vl.find_each(batch_size: 1000) do |vl|
      vl.update(quantity: 0, check: false)
    end


    doc_products.each do |pr|

      data = {
        code: pr["kod"],
        title: pr["name"],
        quantity: pr["ostatok"],
        vendor: pr["vendor"],
        price: pr["cost"],
        barcode: pr["barcode"],
        image: pr["image"],
        check: true
      }

      tov = Vl.find_by(code: data[:code])

      if tov.present?
        tov.update(data)
      else
        Vl.create(data)
      end

    end
      puts "====>>>> FINISH Import Vl === #{Time.now}"
  end

  def self.linking
    Vl.find_each(batch_size: 1000) do |vl|
      product_sku = "ВЛY#{vl.code}"
      products = Product.where(sku: product_sku)
      products.each do |product|
        product.productid_provider = vl.id
        product.provider_id = 3
        product.save
        vl.productid_product = product.id
        vl.save
      end
    end
  end

  def self.syncronaize
    Product.find_each(batch_size: 1000) do |product|
      if product.sku&.match(/^ВЛY/)
        product.update(quantity: 0)
      end
    end

    Vl.find_each(batch_size: 1000) do |provider_product|

      Product.where(productid_provider: provider_product.id).where(provider_id: 3).each do |insales_product|
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
    file = "#{Rails.root}/public/vls_unlinking.xls"

    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'ВЛ незалинкованные')
    sheet.row(0).push("ID", "ID в таблице Товаров", "Название", "Актуальность", "Остаток", "Цена", "Производитель", "Код производителя", "Barcode", "Картинки")

    products = Vl.where(productid_product: nil).order(:id)

    products.each_with_index do |pr, index|
      id = pr[:id]
      productid_product = pr[:productid_product]
      title = pr[:title]
      check = pr[:check]
      quantity = pr[:quantity]
      price = pr[:price]
      vendor = pr[:vendor]
      vendorcode = pr[:code]
      barcode = pr[:barcode]
      image = pr[:image]

      sheet.row(index + 1).push(
        id,
        productid_product,
        title,
        check ? 'был' : 'не был',
        quantity,
        price,
        vendor,
        vendorcode,
        barcode,
        image
      )
    end

    book.write file
  end
end
