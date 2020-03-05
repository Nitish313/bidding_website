class Notification < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :receiver, class_name: "User"
  belongs_to :notifiable, polymorphic: true
  
  validates_presence_of :action
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_associations, -> { includes(:actor, :receiver, :notifiable) }
end
