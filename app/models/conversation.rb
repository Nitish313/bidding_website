# A private conversation between two users: a subject, its messages, and each
# participant's own read and trash state.
class Conversation < ApplicationRecord
  has_many :participants, class_name: "ConversationParticipant", dependent: :destroy
  has_many :users, through: :participants
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :conversation

  validates :subject, presence: true, length: { maximum: 255 }

  # Every conversation the user takes part in, including trashed ones.
  scope :involving, ->(user) { joins(:participants).where(conversation_participants: { user_id: user.id }) }
  # The user's conversation list: not trashed by them, most recent activity first.
  scope :visible_to, lambda { |user|
    involving(user).where(conversation_participants: { trashed: false }).order(updated_at: :desc, id: :desc)
  }
  # Visible conversations with a message from someone else (including a since-deleted
  # user) that arrived after the user last read it. One query, however many there are.
  scope :unread_by, lambda { |user|
    unread_messages = Message.where("messages.conversation_id = conversations.id")
                             .where("messages.sender_id IS NULL OR messages.sender_id <> ?", user.id)
                             .where("conversation_participants.last_read_at IS NULL " \
                                    "OR messages.created_at > conversation_participants.last_read_at")
    visible_to(user).where(unread_messages.arel.exists)
  }

  # Creates the conversation, both participants and the first message. Returns the message.
  def self.start(sender:, recipient:, subject:, body:)
    transaction do
      conversation = new(subject: subject)
      if sender == recipient
        conversation.errors.add(:base, "You can't start a conversation with yourself")
        raise ActiveRecord::RecordInvalid, conversation
      end

      conversation.save!
      conversation.participants.create!(user: sender, last_read_at: Time.current)
      conversation.participants.create!(user: recipient)
      conversation.messages.create!(sender: sender, body: body)
    end
  end

  # Adds a message from a participant. A reply brings the conversation back for
  # anyone who had moved it to trash.
  def reply(sender:, body:)
    transaction do
      message = messages.create!(sender: sender, body: body)
      participants.where(trashed: true).find_each { |participant| participant.update!(trashed: false) }
      message
    end
  end

  def participant_for(user)
    participants.find_by(user_id: user.id)
  end

  # Uses the already loaded participants when the caller preloaded them.
  def other_participant(user)
    users.find { |participant| participant.id != user.id }
  end

  def originator
    messages.first&.sender
  end

  def unread_for?(user)
    Conversation.unread_by(user).exists?(id)
  end

  def mark_as_read(user)
    participant_for(user)&.update!(last_read_at: Time.current)
  end

  def move_to_trash(user)
    participant_for(user)&.update!(trashed: true)
  end
end
