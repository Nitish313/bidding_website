class Skill < ApplicationRecord
  has_many :abilities
  has_many :gigs, through: :abilities

  validates :name, presence: true, length: { maximum: 255 }
end
