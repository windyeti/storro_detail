namespace :mb do
  task first_sync: :environment do
    Product.all.find_each(batch_size: 1000) do |product|
      if product.sku =~ /^[МБ]/
        vendorcode = product.sku.sub(/^МБ/, '')
        Mb.all.find_each(batch_size: 1000) do |mb|
          if mb.vendorcode == vendorcode
            product.productid_provider = mb.id
            product.provider_id = 1
            product.save
            p product
          end
        end
      end
    end
  end
end
