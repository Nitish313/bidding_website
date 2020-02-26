class Category < ApplicationRecord
  has_many :gigs, dependent: :destroy
end