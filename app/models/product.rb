class Product < ApplicationRecord

  require 'open-uri'

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cattitle ASC').select(:cattitle).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }
  validates :sku, uniqueness: true

  def self.import
    puts 'start import '+Time.now.in_time_zone('Moscow').to_s
    Product.update_all(quantity: 0)
    url = "https://idcollection.ru/catalogue/producers/eichholtz"
    doc = Nokogiri::HTML(open(url, :read_timeout => 50))
		paginate_number = doc.css(".pagenavigation__nav.pagenavigation__nav--next")[0]['data-max-page']
    if Rails.env.development?
      count = 1
    else
      count = paginate_number.presence || '1'
    end
    puts count
    page_array = Array(1..count.to_i)
		page_array.each do |page|
      cat_l = url+"?PAGEN_2="+page.to_s
      cat_doc = Nokogiri::HTML(open(cat_l, :read_timeout => 50))
        product_urls = cat_doc.css('.catalog-section__title-link')
        product_urls.each do |purl|
          pr_url = 'https://idcollection.ru'+purl['href']
          pr_doc = Nokogiri::HTML(open(pr_url, :read_timeout => 50))
          puts pr_url
          title= pr_doc.css('h1').text
          puts title
          desc = pr_doc.css('.catalog-element-description__text').text.strip
          cat_array = []
          pr_doc.css('.breadcrumbs__element--title').each do |c|
            if c.text.strip != 'Каталог'
            cat_array.push(c.text.strip)
            end
          end
          cat = cat_array.join('---')
          sku_array = []
          charact_gab_array = []
          characts_array = []
          pr_doc.css('.catalog-element__block .catalog-element-info__item').each do |file_charact|
            key = file_charact.css('div').first.text.strip
            value = file_charact.css('div').last.text.strip
            if key == 'Артикул'
              sku_array.push(value)
            end
            if key == 'Габариты'
              charact_gab_array.push(value)
            end
            if key != 'Артикул' and key != 'Габариты'
              characts_array.push(key+' : '+value.to_s)
            end
          end
          charact = characts_array.join('---')
          sku = sku_array.join()
          charact_gab = charact_gab_array.join()
          if pr_doc.css('.element-sale').present?
            oldprice = pr_doc.css('.element-sale').text.strip.gsub(' ','').gsub('руб.','').gsub('.0','')
          else
            oldprice = 0
          end
          if pr_doc.css('.element-price').present?
            price = pr_doc.css('.element-price').text.strip.gsub(' ','').gsub('руб.','').gsub('.0','')
          else
            price = 0
          end

          if pr_doc.css('.catalog-element-info__cell.catalog-element-info__cell--full').text.strip.include?('В НАЛИЧИИ')
            quantity = pr_doc.css('.catalog-element-info__cell.catalog-element-info__cell--full .catalog-element-info__cell-item span').text.strip.gsub(' шт.','')
          else
            quantity = 0
          end
          image_array = []
          thumbs = pr_doc.css('.element-slider__nav-image')
          if thumbs.present?
            thumbs.each do |thumb|
              pict = 'https://idcollection.ru'+thumb.css('img')[0]['src'].gsub('/resize/197_140_1','')
              image_array.push(pict)
            end
          else
            if pr_doc.css('.element-slider__image').size > 0
              pict = 'https://idcollection.ru'+pr_doc.css('.element-slider__image')[0]['data-magnify-src']
            else
              pict = ''
            end
            image_array.push(pict)
          end
          image = image_array.join(' ')
          product = Product.find_by_sku(sku)
          if product.present?
            product.update_attributes(title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
          else
            Product.create(sku: sku, title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
          end
        end
    end

    puts 'end import '+Time.now.in_time_zone('Moscow').to_s
  end

end
