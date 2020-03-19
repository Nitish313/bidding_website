class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true
  
  has_many :solutions, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  
  validates_presence_of :name, :bid, :description 
  after_create :create_notification
  
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_associations, -> { includes(:gig, :user) }
  
  def create_notification
    Notification.create(actor_id: self.user.id, receiver_id: self.gig.user.id, action: "proposed", notifiable: self)
  end
end