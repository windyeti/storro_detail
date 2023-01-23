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

    if response.code != 200
      File.open("#{Rails.root}/public/errors_update.txt", 'a') do |f|
        f.write "!!! [#{Time.now}] Цены и Остатки не обновились у поставщика Ashanti\n"
      end
      return
    end

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

    # ПРОВЕРКА НА НАЛИЧИЕ ТОВАРОВ В ФАЙЛЕ
    count_rows = 0

    xlsx.sheets.each do |sheet_name|
      sheet = xlsx.sheet(sheet_name)

      last_row = sheet.last_row.to_i
      (1..last_row).each do |i|
        first_cell = sheet.cell(i, 'A')
        next unless first_cell.to_i.to_s == first_cell
        count_rows += 1
      end
    end

    if count_rows == 0
      File.open("#{Rails.root}/public/errors_update.txt", 'a') do |f|
        f.write "!!! [#{Time.now}] Цены и Остатки не обновились у поставщика Ashanti\n"
      end
      return
    end
    # ПРОВЕРКА НА НАЛИЧИЕ ТОВАРОВ В ФАЙЛЕ -- END

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
        quantity = get_quantity(sheet.cell(i, 'G'))
        data = {
          barcode: sheet.cell(i, 'A'),
          vendorcode: sheet.cell(i, 'B'),
          title: sheet.cell(i, 'D'),
          weight: sheet.cell(i, 'F'),
          quantity: quantity,
          use_until: sheet.cell(i, 'H'),
          price: sheet.cell(i, 'K') ? sheet.cell(i, 'K').to_s.gsub(' ', '').to_f : nil,
          desc: sheet.cell(i, 'P'),
          check: true
        }

        ashanti = Ashanti
                    .find_by(vendorcode: data[:vendorcode])

        ashanti.present? ? ashanti.update(data) : Ashanti.create(data)
      end
      p "====>>> Ашанти все продукты импортировались"
    end
  end

  def self.get_quantity(str)
    result = if str == 'В наличии'
               2000
             else
               str
             end
    result.to_s.remove(/ |> | |>/).to_i
  end

  def self.linking
    p "====>>> Ашанти START LINKING"
    Ashanti.find_each(batch_size: 1000) do |ashanti|
      product_sku = "ACY#{ashanti.vendorcode}"
      products = Product.where(sku: product_sku)
      products.each do |product|
        product.productid_provider = ashanti.id
        product.provider_id = 2
        product.save
        ashanti.productid_product = product.id
        ashanti.save
      end
    end
    p "Ашанти FINISH LINKING <<<===="
  end

  def self.syncronaize
    Product.find_each(batch_size: 1000) do |product|
      if product.sku&.match(/^ACY/)
        product.update(quantity: 0)
      end
    end

    Ashanti.find_each(batch_size: 1000) do |provider_product|

      Product.where(productid_provider: provider_product.id).where(provider_id: 2).each do |insales_product|
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
        # insales_product.price = new_insales_price.round unless new_insales_price.nan?

        insales_product.price = new_insales_price.round if insales_product.provider_price != 0 && !insales_product.provider_price.nil?
        insales_product.provider_price = provider_product_price

        # Komplekt сколько ед-ц входить в ед-цу продажи
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
    file = "#{Rails.root}/public/ashanti_unlinking.xls"

    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'Ashanti незалинкованные')
    sheet.row(0).push("ID", "ID в таблице Товаров", "Название", "Актуальность", "Остаток", "Цена", "Описание", "Код производителя", "Barcode")

    products = Ashanti.where(productid_product: nil).order(:id)

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

      sheet.row(index + 1).push(
        id,
        productid_product,
        title,
        check ? 'был' : 'не был',
        quantity,
        price,
        desc,
        vendorcode,
        barcode
      )
    end

    book.write file
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
