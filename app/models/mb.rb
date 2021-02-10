class Mb < ApplicationRecord

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }

  def self.import
    puts 'СТАРТ YML '+Time.now.to_s
    uri = "http://export.mb-catalog.ru/users/export/yml_download_new.php?email=aichurkin@storro.ru"
    response = RestClient.get uri, :accept => :xml, :content_type => "application/xml"
    data = Nokogiri::XML(response)
    mypr = data.xpath("//offer")

    # перед накатыванием обновления товаров у поставщика
    # все существующим ставим check = false
    # чтобы не удалять товары поставщика, так как их id
    # связан с товарами Product
    Mb.all.find_each(batch_size: 1000) { |mb| mb.check = false }

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
  end

  def self.syncronaize
    Product.all.each do |insales_product|

      # если товар есть у поставщика и его количество более 3, то visible поменяется ниже на true
      insales_product.visible = false

      provider_product = Mb.find(insales_product.productid_provider) rescue nil

      if provider_product.present?
        new_insales_price = (insales_product.price / insales_product.provider_price) * provider_product.price.to_f

        # с округлением по целого по правилу 0.5
        insales_product.price = new_insales_price.round
        insales_product.provider_price = provider_product.price.to_f

        insales_product.visible = true if provider_product.quantity >= 3

      end

      insales_product.save
    end
  end
end
