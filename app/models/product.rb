class Product < ApplicationRecord
  require 'open-uri'
  validates :sku, uniqueness: true

  def self.get_file
    puts 'загружаем файла с остатками - '+Time.now.to_s
    a = Mechanize.new
		a.get("https://order.al-style.kz/site/login")
		form = a.page.forms.first
		form['LoginForm[username]'] = "info@c44.kz"
		form['LoginForm[password]'] = "12345Test"
		form.submit
		page = a.get("https://order.al-style.kz")
		link = page.link_with(:dom_class => "btn btn-default btn-xs btn-info")
		url = "https://order.al-style.kz"+link.href
		filename = url.split('/').last
		puts filename
		download_path = "#{Rails.public_path}"+"/"+filename
		download = open(url)
		IO.copy_stream(download, download_path)
    puts 'закончили загружаем файла с остатками - '+Time.now.to_s

    Product.open_file(download_path)
  end

  def self.open_file(file)
    puts 'обновляем из файла - '+Time.now.to_s
		spreadsheet = open_spreadsheet(file)
		header = spreadsheet.row(1)
    if Rails.env.development?
      last_number = 120
    else
      last_number = spreadsheet.last_row.to_i
    end
	    (2..last_number).each do |i|
  			row = Hash[[header, spreadsheet.row(i)].transpose]

  			sku = row["Код"]
  			skubrand = row["Артикул"]
  			title = row["Наименование"]
  			sdesc = row["Полное наименование"]
  			costprice = row["Цена дил."]
  			price = row["Цена роз."]
        quantity = row["Остаток"].to_s.gsub('>','') if row["Остаток"] != nil
        if title.present?
    			product = Product.find_by_sku(sku)
    			if product.present?
    				product.update_attributes(skubrand: skubrand, title: title, sdesc: sdesc, costprice: costprice, price: price, quantity: quantity)
    			else
    				Product.create(sku: sku, skubrand: skubrand, title: title, sdesc: sdesc, costprice: costprice, price: price, quantity: quantity)
    			end
        end
      end

		puts 'конец обновляем из файла - '+Time.now.to_s
  end

  def self.open_spreadsheet(file)
      if file.is_a? String
        Roo::Excelx.new(file)
      else
	    case File.extname(file.original_filename)
	    when ".csv" then Roo::CSV.new(file.path)#csv_options: {col_sep: ";",encoding: "windows-1251:utf-8"})
	    when ".xls" then Roo::Excel.new(file.path)
	    when ".xlsx" then Roo::Excelx.new(file.path)
	    when ".XLS" then Roo::Excel.new(file.path)
	    else raise "Unknown file type: #{file.original_filename}"
      end
	    end
	end

end
