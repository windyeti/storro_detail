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
    				product.update_attributes(skubrand: skubrand, title: title, sdesc: sdesc, costprice: costprice, quantity: quantity)
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

  def self.load_by_api
    puts 'загружаем данные api - '+Time.now.to_s

    count = Product.where(barcode: [nil, '']).order(:id).size
    offset = 0
    while count > 0
      puts "offset - "+offset.to_s
      products = Product.where(barcode: [nil, '']).order(:id).limit(50).offset("#{offset}")
      articles = products.pluck(:sku).join(',')
      # puts articles
      if articles.present?
      url = "https://order.al-style.kz/api/element-info?access-token=Py8UvH0yDeHgN0KQ3KTLP2jDEtCR5ijm&article="+articles+"&additional_fields=barcode,description,brand,properties,detailtext,images,weight,url"
      puts url
      RestClient.get( url ) { |response, request, result, &block|
          case response.code
          when 200
            products = JSON.parse(response)
            products.each do |pr|
              Product.api_update_product(pr)
            end
          when 422
            puts "error 422 - не добавили клиента"
            puts response
            break
          when 404
            puts 'error 404'
            break
          when 503
            sleep 1
            puts 'sleep 1 error 503'
          else
            response.return!(&block)
          end
          }

      count = count - 50
  		offset = offset + 50
  		# sleep 0.1
  		# puts 'sleep 0.1'
      else
        break
      end
		end

    puts 'закончили загружаем данные api - '+Time.now.to_s
  end

  def self.api_update_product(data)
    # data = JSON.parse(pr_info)
    product = Product.find_by_sku(data['article'])
    characts_array = []
    data['properties'].each do |k,v|
      if k != 'Код' and k != 'Базовая единица' and k != 'Короткое наименование' and k != 'Бренд' and k != 'Полное наименование' and k != 'Вес' and k != 'Артикул-PartNumber' and k != 'Анонс'
        characts_array.push(k+' : '+v.to_s)
      end
    end
    characts = characts_array.join('---')
    images = data['images'].join(',')
    product.update_attributes(skubrand: data['article_pn'], barcode: data['barcode'], brand: data['brand'], desc: data['detailtext'], cat: data['category'], charact: characts, image: images, weight: data['weight'], url: data['url'])
  end

  def self.csv_param
	  puts "Файл инсалес c параметрами на лету"
		file = "#{Rails.public_path}"+'/c44kz.csv'
		check = File.file?(file)
		if check.present?
			File.delete(file)
		end
		file_ins = "#{Rails.public_path}"+'/ins_c44kz.csv'
		check = File.file?(file_ins)
		if check.present?
			File.delete(file_ins)
		end

		#создаём файл со статичными данными
		@tovs = Product.order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
		file = "#{Rails.root}/public/c44kz.csv"
		CSV.open( file, 'w') do |writer|
		headers = ['fid','Артикул', 'Штрихкод', 'Название товара', 'Краткое описание', 'Полное описание', 'Цена продажи', 'Остаток', 'Изображения', 'Параметр: Брэнд', 'Параметр: Артикул Производителя', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4', 'Вес' ]

		writer << headers
		@tovs.each do |pr|
			if pr.title != nil
				fid = pr.id
				sku = pr.sku
        barcode = pr.barcode
        title = pr.title
        sdesc = pr.sdesc
        desc = pr.desc
        price = pr.price
        quantity = pr.quantity
				image = pr.image
        brand = pr.brand
        skubrand = pr.skubrand
				cat = '' #pr.cat
				cat1 = '' #pr.cat1
				cat2 = '' #pr.cat2
				cat3 = '' #pr.cat3
        weight = pr.weight
				writer << [fid, sku, barcode, title, sdesc, desc, price, quantity, image, brand, skubrand, cat, cat1, cat2, cat3, weight ]
				end
			end
		end #CSV.open

		#параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
		# дополняем header файла названиями параметров

		vparamHeader = []
		p = @tovs.select(:charact)
		p.each do |p|
			if p.charact != nil
				p.charact.split('---').each do |pa|
					vparamHeader << pa.split(':')[0].strip if pa != nil
				end
			end
		end
		addHeaders = vparamHeader.uniq

		# Load the original CSV file
		rows = CSV.read(file, headers: true).collect do |row|
			row.to_hash
		end

		# Original CSV column headers
		column_names = rows.first.keys
		# Array of the new column headers
		addHeaders.each do |addH|
		additional_column_names = ['Параметр: '+addH]
		# Append new column name(s)
		column_names += additional_column_names
			s = CSV.generate do |csv|
				csv << column_names
				rows.each do |row|
					# Original CSV values
					values = row.values
					# Array of the new column(s) of data to be appended to row
	# 				additional_values_for_row = ['1']
	# 				values += additional_values_for_row
					csv << values
				end
			end
		File.open(file, 'w') { |file| file.write(s) }
		end
		# Overwrite csv file

		# заполняем параметры по каждому товару в файле
		new_file = "#{Rails.public_path}"+'/ins_c44kz.csv'
		CSV.open(new_file, "w") do |csv_out|
			rows = CSV.read(file, headers: true).collect do |row|
				row.to_hash
			end
			column_names = rows.first.keys
			csv_out << column_names
			CSV.foreach(file, headers: true ) do |row|
			fid = row[0]
      puts fid
			vel = Product.find_by_id(fid)
				if vel != nil
# 				puts vel.id
					if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
					vel.charact.split('---').each do |vp|
						key = 'Параметр: '+vp.split(':')[0].strip
						value = vp.split(':')[1].remove('.') if vp.split(':')[1] !=nil
						row[key] = value
					end
					end
				end
			csv_out << row
			end
		end
	puts "Finish Файл инсалес с параметрами на лету"

	# current_process = "создаём файл csv_param"
	# CaseMailer.notifier_process(current_process).deliver_now
	end

end
