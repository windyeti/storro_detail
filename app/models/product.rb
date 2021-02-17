class Product < ApplicationRecord
  require 'open-uri'

  belongs_to :provider, optional: true

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  validate :provider_productid_provider
  validate :product_provider_exist_free

  after_update :after_update_product_provider

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
        return
      end
      # Связываемый Товар Поставщика: не связан с каким-либо Товаром, или наш Товар и есть Товар связанный с Товаром Поставщика
      if product_provider.productid_product.present? && product_provider.productid_product != id
        errors.add(:provider_id, "Выбранный Товар Поставщика уже связанна с другим Товаром")
        errors.add(:productid_provider, "Выбранный Товар Поставщика уже связанна с другим Товаром")
      end
    end
  end

  def after_update_product_provider
    if provider_id.present? && productid_provider.present?
      product_provider = provider.permalink.constantize.find(productid_provider) rescue return
      product_provider.productid_product = id
      product_provider.save
    end
  end

  def self.import_insales_xml
    #
    # puts '=====>>>> СТАРТ InSales YML '+Time.now.to_s
    uri = "https://www.storro.ru/marketplace/75518.xml"
    response = RestClient.get uri, :accept => :xml, :content_type => "application/xml"
    data = Nokogiri::XML(response)
    mypr = data.xpath("//offer")

    categories = {}
    doc_category = data.xpath("category")

    doc_category.each do |c|
      categories[c.xpath("parentId")] = c.text
    end

    mypr.each do |pr|
      data_create = {
        sku: pr.xpath("sku").text,
        title: pr.xpath("model").text,
        url: pr.xpath("url").text,
        desc: pr.xpath("description").text,
        image: pr.xpath("picture").map(&:text).join(' '),
        # quantity: pr.xpath("quantity").text.to_i,
        cat: categories[pr.xpath("categoryId").text],
        price: pr.xpath("price").text.to_f,
        provider_price: pr.xpath("cost_price").text.to_f,
        productid_insales: pr["id"],
        productid_var_insales: pr["var_id"]
      }

      data_update = {
        sku: pr.xpath("sku").text,
        title: pr.xpath("model").text,
        url: pr.xpath("url").text,
        desc: pr.xpath("description").text,
        cat: categories[pr.xpath("categoryId").text],
        image: pr.xpath("picture").map(&:text).join(' '),
        price: pr.xpath("price").text.to_f,
        provider_price: pr.xpath("cost_price").text.to_f
      }

      product = Product
                  .find_by(productid_var_insales: data_create[:productid_var_insales])

      product.present? ? product.update_attributes(data_update) : Product.create(data_create)
    end
    # puts '=====>>>> FINISH InSales YML '+Time.now.to_s
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

    products = Product.where.not(provider: nil).where.not(productid_provider: nil).order(:id)

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

#   def self.import
#     puts 'start import '+Time.now.in_time_zone('Moscow').to_s
#     Product.update_all(quantity: 0)
#     url = "https://idcollection.ru/catalogue/producers/eichholtz"
#     doc = Nokogiri::HTML(open(url, :read_timeout => 50))
# 		paginate_number = doc.css(".pagenavigation__nav.pagenavigation__nav--next")[0]['data-max-page']
#     if Rails.env.development?
#       count = 4
#     else
#       count = paginate_number.presence || '1'
#     end
#     puts count
#     page_array = Array(1..count.to_i)
# 		page_array.each do |page|
#       puts 'page '+page.to_s
#       cat_l = url+"?PAGEN_2="+page.to_s
#       cat_doc = Nokogiri::HTML(open(cat_l, :read_timeout => 50))
#         product_urls = cat_doc.css('.catalog-section__title-link')
#         product_urls.each do |purl|
#           pr_url = 'https://idcollection.ru'+purl['href']
#           pr_doc = Nokogiri::HTML(open(pr_url, :read_timeout => 50))
#           puts pr_url
#           title= pr_doc.css('h1').text
#           # puts title
#           desc = pr_doc.css('.catalog-element-description__text').text.strip
#           cat_array = []
#           pr_doc.css('.breadcrumbs__element--title').each do |c|
#             if c.text.strip != 'Каталог'
#             cat_array.push(c.text.strip)
#             end
#           end
#           cat = cat_array.join('---')
#           sku_array = []
#           charact_gab_array = []
#           characts_array = []
#           pr_doc.css('.catalog-element__block .catalog-element-info__item').each do |file_charact|
#             key = file_charact.css('div').first.text.strip
#             value = file_charact.css('div').last.text.strip
#             if key == 'Артикул'
#               sku_array.push(value)
#             end
#             if key == 'Габариты'
#               charact_gab_array.push(value)
#             end
#             if key != 'Артикул' and key != 'Габариты'
#               characts_array.push(key+' : '+value.to_s)
#             end
#           end
#           charact = characts_array.join('---')
#           sku = sku_array.join()
#           charact_gab = charact_gab_array.join().gsub('cm', '').gsub('см', '')
#           if pr_doc.css('.element-sale').present?
#             oldprice = pr_doc.css('.element-sale').text.strip.gsub(' ','').gsub('руб.','').gsub('.0','')
#           else
#             oldprice = 0
#           end
#           if pr_doc.css('.element-price').present?
#             price = pr_doc.css('.element-price').text.strip.gsub(' ','').gsub('руб.','').gsub('.0','')
#           else
#             price = 0
#           end
#
#           if pr_doc.css('.catalog-element-info__cell.catalog-element-info__cell--full').text.strip.include?('В НАЛИЧИИ')
#             quantity = pr_doc.css('.catalog-element-info__cell.catalog-element-info__cell--full .catalog-element-info__cell-item span').text.strip.gsub(' шт.','')
#           else
#             quantity = 0
#           end
#           image_array = []
#           thumbs = pr_doc.css('.element-slider__nav-image')
#           if thumbs.present?
#             thumbs.each do |thumb|
#               pict = 'https://idcollection.ru'+thumb.css('img')[0]['src'].gsub('/resize/197_140_1','')
#               image_array.push(pict)
#             end
#           else
#             if pr_doc.css('.element-slider__image').size > 0
#               pict = 'https://idcollection.ru'+pr_doc.css('.element-slider__image')[0]['data-magnify-src']
#             else
#               pict = ''
#             end
#             image_array.push(pict)
#           end
#           image = image_array.join(' ')
#           product = Product.find_by_sku(sku)
#           if product.present?
#             product.update_attributes(title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
#           else
#             Product.create(sku: sku, title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
#           end
#         end
#     end
#
#     productcount = Product.product_qt_not_null_size ||= "0"
# 		productall = Product.product_all_size ||= "0"
#     # ProductMailer.downloadproduct_product(productcount, productall).deliver_now
#     puts 'end import '+Time.now.in_time_zone('Moscow').to_s
#   end
#
#   def self.csv_param
#     products = Product.all.order(:id)
#     Product.csv_param_selected(products, 'full')
#   end
#
#   def self.csv_param_selected(products, otchet_type)
#     if otchet_type == 'selected'
#       file = "#{Rails.public_path}"+'/detail_selected.csv'
#     else
# 		  file = "#{Rails.public_path}"+'/detail.csv'
#     end
# 		check = File.file?(file)
# 		if check.present?
# 			File.delete(file)
# 		end
#
#     if otchet_type == 'selected'
#       file_ins = "#{Rails.public_path}"+'/ins_detail_selected.csv'
#     else
# 		  file_ins = "#{Rails.public_path}"+'/ins_detail.csv'
#     end
# 		check = File.file?(file_ins)
# 		if check.present?
# 			File.delete(file_ins)
# 		end
#
# 		#создаём файл со статичными данными
# 		@tovs = Product.where(id: products).order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
#     if otchet_type == 'selected'
#       file = "#{Rails.root}/public/detail_selected.csv"
#     else
#       file = "#{Rails.root}/public/detail.csv"
#     end
# 		CSV.open( file, 'w') do |writer|
# 		headers = ['fid','Артикул', 'Название товара', 'Полное описание', 'Цена продажи', 'Старая цена' , 'Остаток', 'Изображения', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4', 'Параметр: Ширина', 'Параметр: Глубина', 'Параметр: Высота', 'Параметр: Глубина сиденья', 'Параметр: Высота сиденья', 'Параметр: Диаметр' ]
#
# 		writer << headers
# 		@tovs.each do |pr|
# 			if pr.title != nil
#         puts "pr.id - "+pr.id.to_s
# 				fid = pr.id
# 				sku = pr.sku
#         title = pr.title.gsub('Eichholtz','').gsub(sku,'')
#         desc = pr.desc
#         price = pr.price
#         oldprice = pr.oldprice
#         quantity = pr.quantity
# 				image = pr.image
# 				cat = pr.cat.split('---')[0] || '' if pr.cat != nil
# 				cat1 = pr.cat.split('---')[1] || '' if pr.cat != nil
# 				cat2 = pr.cat.split('---')[2] || '' if pr.cat != nil
# 				cat3 = pr.cat.split('---')[3] || '' if pr.cat != nil
#         charact_gab = pr.charact_gab
#
#         shirina = ''
#         glubina = ''
#         visota = ''
#         glubina_sid = ''
#         visota_sid = ''
#         diametr = ''
#
#         if charact_gab.include?('A.') and charact_gab.include?('Б.')
#           shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? and charact_gab.split('|')[0].include?('A.')
#           glubina = charact_gab.split('|')[1].gsub('Б. ', '') if !charact_gab.split('|')[1].nil? and charact_gab.split('|')[1].include?('Б.')
#           visota = charact_gab.split('|')[2].gsub('С. ', '') if !charact_gab.split('|')[2].nil? and charact_gab.split('|')[2].include?('С.')
#           glubina_sid = charact_gab.split('|')[3].gsub('Д. ', '') if !charact_gab.split('|')[3].nil? and charact_gab.split('|')[3].include?('Д.')
#           visota_sid = charact_gab.split('|')[4].gsub('Е. ', '') if !charact_gab.split('|')[4].nil? and charact_gab.split('|')[4].include?('Е.')
#         end
#         if charact_gab.include?('A.') and charact_gab.include?('B.')
#           shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? and charact_gab.split('|')[0].include?('A.')
#           glubina = charact_gab.split('|')[1].gsub('B. ', '') if !charact_gab.split('|')[1].nil? and charact_gab.split('|')[1].include?('B.')
#           visota = charact_gab.split('|')[2].gsub('C. ', '') if !charact_gab.split('|')[2].nil? and charact_gab.split('|')[2].include?('C.')
#           glubina_sid = charact_gab.split('|')[3].gsub('D. ', '') if !charact_gab.split('|')[3].nil? and charact_gab.split('|')[3].include?('D.')
#           visota_sid = charact_gab.split('|')[4].gsub('E. ', '') if !charact_gab.split('|')[4].nil? and charact_gab.split('|')[4].include?('E.')
#         end
#         if charact_gab.split('x').size == 3 and charact_gab.include?('H.') and !charact_gab.include?('ø')
#           shirina = charact_gab.split('x')[0]
#           glubina = charact_gab.split('x')[1]
#           visota = charact_gab.split('x')[2].gsub('H.', '')
#         end
#         if charact_gab.split('x').size == 3  and charact_gab.include?('высота') and !charact_gab.include?('ø')
#           shirina = charact_gab.split('x')[0]
#           glubina = charact_gab.split('x')[1]
#           visota = charact_gab.split('x')[2].gsub('высота', '')
#         end
#         if charact_gab.split('x').size == 3  and charact_gab.include?('H.') and charact_gab.include?('ø')
#           diametr = charact_gab.split('x')[0]
#           glubina = charact_gab.split('x')[1]
#           visota = charact_gab.split('x')[2].gsub('H.', '')
#         end
#         if charact_gab.split('x').size == 2 and charact_gab.include?('ø')
#           diametr = charact_gab.split('x')[0].gsub('ø ', '')
#           visota = charact_gab.split('x')[1].gsub('H.', '')
#         end
#         if charact_gab.split('x').size == 2 and !charact_gab.include?('ø')
#           shirina = charact_gab.split('x')[0]
#           glubina = charact_gab.split('x')[1]
#         end
#         writer << [fid, sku, title, desc, price, oldprice, quantity, image, cat, cat1, cat2, cat3, shirina, glubina, visota, glubina_sid, visota_sid, diametr ]
# 				end
# 			end
# 		end #CSV.open
#
# 		#параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
# 		# дополняем header файла названиями параметров
#
# 		vparamHeader = []
# 		p = @tovs.select(:charact)
# 		p.each do |p|
# 			if p.charact != nil
# 				p.charact.split('---').each do |pa|
# 					vparamHeader << pa.split(':')[0].strip if pa != nil
# 				end
# 			end
# 		end
# 		addHeaders = vparamHeader.uniq
#
# 		# Load the original CSV file
# 		rows = CSV.read(file, headers: true).collect do |row|
# 			row.to_hash
# 		end
#
# 		# Original CSV column headers
# 		column_names = rows.first.keys
# 		# Array of the new column headers
# 		addHeaders.each do |addH|
#     		additional_column_names = ['Параметр: '+addH]
#     		# Append new column name(s)
#     		column_names += additional_column_names
#     			s = CSV.generate do |csv|
#     				csv << column_names
#     				rows.each do |row|
#     					# Original CSV values
#     					values = row.values
#     					# Array of the new column(s) of data to be appended to row
#     	# 				additional_values_for_row = ['1']
#     	# 				values += additional_values_for_row
#     					csv << values
#     				end
#     			end
#     		File.open(file, 'w') { |file| file.write(s) }
# 		end
# 		# Overwrite csv file
#
# 		# заполняем параметры по каждому товару в файле
#     if otchet_type == 'selected'
#       new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
#     else
# 		  new_file = "#{Rails.public_path}"+'/ins_detail.csv'
#     end
# 		CSV.open(new_file, "w") do |csv_out|
# 			rows = CSV.read(file, headers: true).collect do |row|
# 				row.to_hash
# 			end
# 			column_names = rows.first.keys
# 			csv_out << column_names
# 			CSV.foreach(file, headers: true ) do |row|
# 			fid = row[0]
#       # puts fid
# 			vel = Product.find_by_id(fid)
# 				if vel != nil
# # 				puts vel.id
# 					if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
# 					vel.charact.split('---').each do |vp|
# 						key = 'Параметр: '+vp.split(':')[0].strip
#             if vp.split(':')[0].strip != 'Материал'
# 						  value = vp.split(':')[1].remove('.').strip.split.map(&:capitalize).join(' ') if vp.split(':')[1] !=nil
#             end
#             if vp.split(':')[0].strip == 'Материал'
#               value = vp.split(':')[1].remove('.').strip.split(', ').map(&:capitalize).join(',').gsub(',','##') if vp.split(':')[1] !=nil
#             end
# 						row[key] = value
# 					end
# 					end
# 				end
# 			csv_out << row
# 			end
# 		end
#
#     # ProductMailer.ins_file(new_file).deliver_now
# 	end
#
#   def self.clean_sm
#     products = Product.all
#     products.each do |pr|
#       pr.charact_gab = pr.charact_gab.gsub('cm', '').gsub('см', '')
#       pr.save
#     end
#   end

end
