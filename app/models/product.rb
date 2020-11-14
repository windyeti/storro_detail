class Product < ApplicationRecord

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cattitle ASC').select(:cattitle).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }
  validates :sku, uniqueness: true

end
