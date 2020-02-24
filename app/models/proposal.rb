class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true
  has_many :solutions, dependent: :destroy
end