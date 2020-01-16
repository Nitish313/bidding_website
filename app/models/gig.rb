class Gig < ApplicationRecord
  belongs_to :user, optional: true
  has_many :proposals
  belongs_to :category, optional: true
  has_many :abilities
  has_many :skills, through: :abilities
end