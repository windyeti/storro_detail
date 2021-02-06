class Provider < ApplicationRecord
  has_many :products

  validates :prefix, :name, :permalink, uniqueness: true
  validates :prefix, :name, :permalink, presence: true
end
