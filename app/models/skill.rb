class Skill < ApplicationRecord
  has_many :abilities
  has_many :gigs, through: :abilities
end