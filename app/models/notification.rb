class Notification < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :receiver, class_name: "User"
  belongs_to :notifiable, polymorphic: true
end
