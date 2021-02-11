class ProductImportJob < ApplicationJob
  queue_as :default

  def perform(path_file, extend_file)
    Product.import_insales(path_file, extend_file)
  end
end
