class Provider < ApplicationRecord
  validates :prefix, :name, :permalink, uniqueness: true
  validates :prefix, :name, :permalink, presence: true
end
