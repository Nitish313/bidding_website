class Category < ApplicationRecord
  has_many :gigs, dependent: :destroy
  validates :name, presence: true
end