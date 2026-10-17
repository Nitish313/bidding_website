# One message in a conversation. The sender is kept as nil if their account is deleted.
class Message < ApplicationRecord
  belongs_to :conversation, touch: true, inverse_of: :messages
  belongs_to :sender, class_name: "User", optional: true
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 32_000 }
  validates :sender, presence: true, on: :create
  validate :sender_takes_part_in_conversation, on: :create

  private

  def sender_takes_part_in_conversation
    return if sender.nil? || conversation.nil?
    return if conversation.participants.exists?(user_id: sender.id)

    errors.add(:sender, "is not part of this conversation")
  end
end
