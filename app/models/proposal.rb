class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true
  has_many :solutions, dependent: :destroy
  after_create :create_notifications

  private
    def create_notifications
      @recipient = self.gig.user

      Notification.create(recipient: @recipient, actor: self.user,
        action: 'proposed', notifiable: self)
    end
end