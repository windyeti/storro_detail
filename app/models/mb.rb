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
        param: pr.xpath("param").text
      }

      tov = Mb.find_by_fid(data[:fid])

      if tov.present?
        tov.update(data)
      else
        Mb.create(data)
      end
    end
  end
end
