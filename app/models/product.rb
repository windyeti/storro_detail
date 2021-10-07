class Product < ApplicationRecord
  require 'open-uri'

  belongs_to :provider, optional: true

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  validate :provider_productid_provider
  # validate :product_provider_exist_free

  # after_update :after_update_product_provider

  def provider_productid_provider
    unless (!provider_id.present? && !productid_provider.present?) || (provider_id.present? && productid_provider.present?)
      errors.add(:provider_id, "Оба поля должны быть заполнены или быть пустыми")
      errors.add(:productid_provider, "Оба поля должны быть заполнены или быть пустыми")
    end
  end

  def product_provider_exist_free
    if provider_id.present? && productid_provider.present?
      # Сначала удостоверимся что есть такой Товар Поставщика И он уже не связан с другим Товаром
      begin
        provider = Provider.find(provider_id)
        provider_klass = provider.permalink.constantize
        product_provider = provider_klass.find(productid_provider)
      rescue
        errors.add(:provider_id, "Нет такого Товара у Поставщика или Поставщика")
        errors.add(:productid_provider, "Нет такого Товара у Поставщика или Поставщика")
        File.open("#{Rails.root}/public/errors_update.txt", 'a') do |f|
          f.write "[#{Time.now}] - Артикул Товара: #{sku} -- Поставщик: #{Provider.find(provider_id).name} -- ID Товара Поставщика:#{productid_provider} -- Ошибка: Нет такого Товара у Поставщика или Поставщика\n"
        end
        return
      end
      # Связываемый Товар Поставщика: не связан с каким-либо Товаром, или наш Товар и есть Товар связанный с Товаром Поставщика
      if product_provider.productid_product.present? && product_provider.productid_product != id
        errors.add(:provider_id, "Выбранный Товар Поставщика уже связанна с другим Товаром")
        errors.add(:productid_provider, "Выбранный Товар Поставщика уже связанна с другим Товаром")
        File.open("#{Rails.root}/public/errors_update.txt", 'a') do |f|
          f.write "[#{Time.now}] - Артикул Товара: #{sku} -- Поставщик: #{Provider.find(provider_id).name} -- ID Товара Поставщика:#{productid_provider} -- Ошибка: Выбранный Товар Поставщика уже связанна с другим Товаром\n"
        end
      end
    end
  end

  # def after_update_product_provider
  #   if provider_id.present? && productid_provider.present?
  #     p product_provider = provider.permalink.constantize.find(productid_provider) rescue return
  #     p product_provider.productid_product = id
  #     product_provider.save
  #     p product_provider
  #   end
  # end

  def self.update_price_quantity_all_providers
    begin
      Product.import_insales_xml
      # Здесь будут синхронизации всех поставщиков
      Mb.import_linking_syncronaize
      Ashanti.import_linking_syncronaize
      Vl.import_linking_syncronaize
      Product.create_csv
    rescue
      data_email = {
        subject: 'Оповещение: Проблема с Приложением',
        message: 'Оповещение: Проблема с Приложением'
      }
      NotificationMailer.send_notify(data_email).deliver_later
    end
  end

  def self.import_insales_xml
    #
    puts '=====>>>> СТАРТ InSales YML '+Time.now.to_s
    uri = "https://www.storro.ru/marketplace/75518.xml"
    response = RestClient.get uri, :accept => :xml, :content_type => "application/xml"
    data = Nokogiri::XML(response)
    mypr = data.xpath("//offer")

    categories = {}
    doc_category = data.xpath("//category")

    doc_category.each do |c|
      categories[c["id"]] = c.text
    end

    mypr.each do |pr|

      data_create = {
        sku: pr.xpath("sku").text,
        title: pr.xpath("model").text,
        url: pr.xpath("url").text,
        desc: pr.xpath("description").text,
        image: pr.xpath("picture").map(&:text).join(' '),
        cat: categories[pr.xpath("categoryId").text],
        price: pr.xpath("price").text.to_f,
        provider_price: pr.xpath("cost_price").text.to_f,
        productid_insales: pr["id"],
        productid_var_insales: pr["var_id"],
        komplekt: pr.xpath("komplekt").text.present? ? pr.xpath("komplekt").text.to_f : nil
      }

      data_update = {
        sku: pr.xpath("sku").text,
        title: pr.xpath("model").text,
        url: pr.xpath("url").text,
        desc: pr.xpath("description").text,
        cat: categories[pr.xpath("categoryId").text],
        image: pr.xpath("picture").map(&:text).join(' '),
        price: pr.xpath("price").text.to_f,
        provider_price: pr.xpath("cost_price").text.to_f,
        komplekt: pr.xpath("komplekt").text.present? ? pr.xpath("komplekt").text.to_f : nil
      }

      product = Product
                  .find_by(productid_var_insales: data_create[:productid_var_insales])

      product.present? ? product.update_attributes(data_update) : Product.create(data_create)
    end
    puts '=====>>>> FINISH InSales YML '+Time.now.to_s
  end

  def self.import_insales(path_file, extend_file)

    spreadsheets = open_spreadsheet(path_file, extend_file)
    last_spreadsheet = spreadsheets.last_row.to_i
    # header = spreadsheets.row(1)
    #
    (2..last_spreadsheet).each do |i|

      data_create = {
        sku: spreadsheets.cell(i, 'Z'),
        title: spreadsheets.cell(i, 'B'),
        url: spreadsheets.cell(i, 'D'),
        desc: spreadsheets.cell(i, 'F'),
        # quantity: spreadsheets.cell(i, 'AH').to_i,
        cat: spreadsheets.cell(i, 'L'),
        image: spreadsheets.cell(i, 'R'),
        # oldprice: spreadsheets.cell(i, 'AD'),
        price: spreadsheets.cell(i, 'AC').to_f,
        provider_price: spreadsheets.cell(i, 'AE').to_f,
        productid_insales: spreadsheets.cell(i, 'A'),
        productid_var_insales: spreadsheets.cell(i, 'Y'),
        product_sku_provider: spreadsheets.cell(i, 'X'),
        visible: spreadsheets.cell(i, 'G') == 'скрыт' ? false : true
      }

      data_update = {
        sku: spreadsheets.cell(i, 'Z'),
        title: spreadsheets.cell(i, 'B'),
        url: spreadsheets.cell(i, 'D'),
        desc: spreadsheets.cell(i, 'F'),
        cat: spreadsheets.cell(i, 'L'),
        image: spreadsheets.cell(i, 'R'),
        price: spreadsheets.cell(i, 'AC').to_f,
        provider_price: spreadsheets.cell(i, 'AE').to_f
        # quantity: spreadsheets.cell(i, 'AH').to_i
      }

      product = Product
                  .find_by(productid_var_insales: data_create[:productid_var_insales])

      product.present? ? product.update(data_update) : Product.create(data_create)
    end
    # отправка почты
    # ProductMailer.ins_file(new_file).deliver_now
  end

  def self.open_spreadsheet(path_file, extend_file)
    case extend_file
    when ".csv" then Roo::Spreadsheet.open(path_file, { csv_options: { encoding: 'bom|utf-8', col_sep: "\t" } })
      # when ".csv" then Roo::CSV.new(file.path)
      # when ".csv" then Roo::CSV.new(file.path, csv_options: {col_sep: "\t"})
    when ".xls" then Roo::Excel.new(path_file)
    when ".xlsx" then Roo::Excelx.new(path_file)
    when ".XLS" then Roo::Excel.new(path_file)
    else raise "Unknown file type"
    end
  end

  def self.create_csv
    file = "#{Rails.root}/public/export_insales.csv"
    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    products = Product.where("sku ~* ?", 'МБ|ACY|ВЛY').order(:id)
    # products = Product.order(:id)
    # products = Product.where.not(provider: nil).where.not(productid_provider: nil).order(:id)

    CSV.open("#{Rails.root}/public/export_insales.csv", "wb") do |writer|
      headers = [ 'ID варианта товара', 'Артикул', 'Название товара', 'Цена продажи', 'Цена закупки', 'Склад Удаленный' ]

      writer << headers
      products.each do |pr|
          productid_var_insales = pr.productid_var_insales
          title = pr.title
          sku = pr.sku
          price = pr.price
          provider_price = pr.provider_price
          store = pr.quantity

          writer << [productid_var_insales, sku, title, price, provider_price, store]
      end
    end #CSV.open
  end

end
