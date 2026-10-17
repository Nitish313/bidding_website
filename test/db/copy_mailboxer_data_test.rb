require "test_helper"
require Rails.root.join("db/migrate/20261017175700_copy_mailboxer_data").to_s

# Builds data through mailboxer, the way the app creates it today, then checks the copy.
class CopyMailboxerDataTest < ActiveSupport::TestCase
  def setup
    @client = users(:client)
    @freelancer = users(:freelancer)
    @rival = users(:rival)
  end

  def copy
    ActiveRecord::Migration.suppress_messages { CopyMailboxerData.new.migrate(:up) }
  end

  def undo
    ActiveRecord::Migration.suppress_messages { CopyMailboxerData.new.migrate(:down) }
  end

  def mailboxer_conversation(subject: "Landing page")
    receipt = @client.send_message(@freelancer, "Can you start Monday?", subject)
    travel 1.second
    @freelancer.reply_to_conversation(receipt.conversation, "Yes, Monday works.")
    receipt.conversation
  end

  test "conversations and messages keep their ids, subjects, senders, bodies and order" do
    old = mailboxer_conversation
    copy
    conversation = Conversation.find(old.id)
    assert_equal "Landing page", conversation.subject
    assert_equal old.messages.order(:created_at, :id).pluck(:id), conversation.messages.pluck(:id)
    assert_equal [@client, @freelancer], conversation.messages.map(&:sender)
    assert_equal ["Can you start Monday?", "Yes, Monday works."], conversation.messages.map(&:body)
    assert_equal [@client, @freelancer].sort_by(&:id), conversation.users.sort_by(&:id)
  end

  test "each participant keeps their own unread state" do
    old = mailboxer_conversation
    old.mark_as_read(@freelancer)
    copy
    conversation = Conversation.find(old.id)
    assert conversation.unread_for?(@client), "the client has not read the freelancer's reply"
    assert_not conversation.unread_for?(@freelancer), "the freelancer read everything"
  end

  test "a conversation trashed by one participant stays trashed only for them" do
    old = mailboxer_conversation
    old.move_to_trash(@freelancer)
    copy
    conversation = Conversation.find(old.id)
    assert_not_includes Conversation.visible_to(@freelancer), conversation
    assert_includes Conversation.visible_to(@client), conversation
  end

  test "notifications that pointed at mailboxer receipts now point at the copied message" do
    receipt = @client.send_message(@freelancer, "Can you start Monday?", "Landing page")
    notification = Notification.create!(actor_id: @client.id, receiver_id: @freelancer.id,
                                        action: "started a conversation", notifiable: receipt)
    copy
    notification.reload
    assert_equal "Message", notification.notifiable_type
    assert_equal receipt.notification_id, notification.notifiable_id
    assert_equal "Landing page", notification.notifiable.conversation.subject
  end

  test "messages from deleted users are kept without a sender" do
    receipt = @rival.send_message(@freelancer, "Hello", "Intro")
    User.where(id: @rival.id).delete_all
    copy
    message = Conversation.find(receipt.conversation.id).messages.first
    assert_nil message.sender
    assert_equal "Hello", message.body
  end

  test "running the copy again changes nothing" do
    mailboxer_conversation
    copy
    assert_no_difference ["Conversation.count", "Message.count", "ConversationParticipant.count"] do
      copy
    end
  end

  test "rolling back removes the copies and points notifications back at mailboxer" do
    receipt = @client.send_message(@freelancer, "Can you start Monday?", "Landing page")
    notification = Notification.create!(actor_id: @client.id, receiver_id: @freelancer.id,
                                        action: "started a conversation", notifiable: receipt)
    copy
    undo
    assert_equal 0, Conversation.count
    assert_equal 0, Message.count
    notification.reload
    assert_equal "Mailboxer::Receipt", notification.notifiable_type
    assert_equal receipt.id, notification.notifiable_id
  end
end
