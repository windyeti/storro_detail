class Ashanti < ApplicationRecord

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  def self.import

    uri = "https://ashaindia.ru/price/Прайс-лист_Ashanti_без_отсутствующих.xlsx"
    ascii_uri = URI.encode(uri)
    response = RestClient.get(ascii_uri)

    file_path = "#{Rails.root}/public/ashanti_import.xlsx"

    if response.code == 200
      check = File.file?(file_path)
      if check.present?
        File.delete(file_path)
      end

      f = File.new(file_path, "wb")
      f << response.body
      puts "XSLS Complited"
      f.close
    end

    file = File.open(file_path)
    xlsx = open_spreadsheet(file)

    Ashanti.all.find_each(batch_size: 1000) do |mb|
      mb.check = false
      mb.quantity = 0
      mb.save
    end

    xlsx.sheets.each do |sheet_name|
      sheet = xlsx.sheet(sheet_name)

      last_row = sheet.last_row.to_i
      (1..last_row).each do |i|
        first_cell = sheet.cell(i, 'A')
        next unless first_cell.to_i.to_s == first_cell

        data = {
          barcode: sheet.cell(i, 'A'),
          vendorcode: sheet.cell(i, 'B'),
          title: sheet.cell(i, 'D'),
          weight: sheet.cell(i, 'E'),
          quantity: sheet.cell(i, 'F') == 'В наличии' ? 2000 : 0,
          use_until: sheet.cell(i, 'G'),
          price: sheet.cell(i, 'I').to_f,
          desc: sheet.cell(i, 'N'),
          check: true
        }

        ashanti = Ashanti
                    .find_by(barcode: data[:barcode])

        ashanti.present? ? ashanti.update(data) : Ashanti.create(data)
      end
    end
  end

  def self.linking
    Ashanti.find_each(batch_size: 1000) do |ashanti|
      product_sku = "ACY#{ashanti.vendorcode}"
      product = Product.find_by(sku: product_sku)
      if product
        product.productid_provider = ashanti.id
        product.provider_id = 2
        product.save
        ashanti.productid_product = product.id
        ashanti.save
      end
    end
  end

  def self.syncronaize
    Ashanti.find_each(batch_size: 1000) do |provider_product|

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
  end

  def self.unlinking_to_csv
    file = "#{Rails.root}/public/ashanti_unlinking.csv"
    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    products = Ashanti.where(productid_product: nil).order(:id)

    CSV.open("#{Rails.root}/public/ashanti_unlinking.csv", "wb") do |writer|
      headers = [ "ID", "ID в таблице Товаров", "Название", "Актуальность", "Остаток", "Цена", "Описание", "Код производителя", "Barcode" ]

      writer << headers
      products.each do |pr|
        id = pr[:id]
        productid_product = pr[:productid_product]
        title = pr[:title]
        check = pr[:check]
        quantity = pr[:quantity]
        price = pr[:price]
        desc = pr[:desc]
        vendorcode = pr[:vendorcode]
        barcode = pr[:barcode]

        writer << [
          id,
          productid_product,
          title,
          check ? 'был' : 'не был',
          quantity,
          price,
          desc,
          vendorcode,
          barcode
        ]
      end
    end #CSV.open
  end

  def self.open_spreadsheet(file)
    case File.extname(file)
    when ".csv" then Roo::CSV.new(file.path) #csv_options: {col_sep: ";",encoding: "windows-1251:utf-8"})
    when ".xls" then Roo::Excel.new(file.path)
    when ".xlsx" then Roo::Spreadsheet.open(file.path, extension: :xlsx)
    # when ".xlsx" then Roo::Excelx.new(file.path, extension: :xlsx)
    when ".XLS" then Roo::Excel.new(file.path)
    else raise "Unknown file type: #{File.extname(file)}"
    end
  end

end
