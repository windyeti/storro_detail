json.extract! product, :id, :sku, :skubrand, :barcode, :title, :sdesc, :desc, :cat, :catins, :costprice, :price, :quantity, :image, :weight, :url, :created_at, :updated_at
json.url product_url(product, format: :json)
