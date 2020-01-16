class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true
end