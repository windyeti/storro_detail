class Provider < ApplicationRecord
  validates :name, uniqueness: true
  validates :prefix, presence: true
end
