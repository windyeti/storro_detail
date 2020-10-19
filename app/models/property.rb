class Property < ApplicationRecord

  scope :property_status_true, -> { where(status: true) }
  #scope :sort_by_reverse_name_asc, lambda { order("REVERSE(name) ASC") }
  validates :title, uniqueness: true

end
