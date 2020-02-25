class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true
  has_many :solutions, dependent: :destroy
  has_many :notifications, as: :notifiable

  after_create :create_notification


  def create_notification
    Notification.create(actor_id: self.user.id,
                        receiver_id: self.gig.user.id,
                        action: "proposed",
                        notifiable: self
                        )
  end
end