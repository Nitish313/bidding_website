require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  def setup
    @client = users(:client)
    @freelancer = users(:freelancer)
    @rival = users(:rival)
  end

  def start(sender: @client, recipient: @freelancer, subject: "Landing page", body: "Can you start Monday?")
    Conversation.start(sender: sender, recipient: recipient, subject: subject, body: body)
  end

  # starting

  test "starting a conversation creates it with both participants" do
    conversation = start.conversation
    assert_equal "Landing page", conversation.subject
    assert_equal [@client, @freelancer].sort_by(&:id), conversation.users.sort_by(&:id)
  end

  test "the first message comes from the sender, who is the originator" do
    message = start
    assert_equal [message], message.conversation.messages.to_a
    assert_equal @client, message.sender
    assert_equal "Can you start Monday?", message.body
    assert_equal @client, message.conversation.originator
  end

  test "a conversation needs a subject and a first message" do
    assert_raises(ActiveRecord::RecordInvalid) { start(subject: "") }
    assert_raises(ActiveRecord::RecordInvalid) { start(body: "") }
    assert_equal 0, Conversation.count
  end

  test "a conversation cannot be started with yourself" do
    error = assert_raises(ActiveRecord::RecordInvalid) { start(recipient: @client) }
    assert_match "yourself", error.message
    assert_equal 0, Conversation.count
  end

  test "subjects and message bodies have length limits" do
    assert_raises(ActiveRecord::RecordInvalid) { start(subject: "x" * 256) }
    assert_raises(ActiveRecord::RecordInvalid) { start(body: "x" * 32_001) }
    assert_predicate start(subject: "x" * 255, body: "x" * 32_000), :persisted?
  end

  # replying

  test "a participant replies and the reply comes last" do
    conversation = start.conversation
    reply = conversation.reply(sender: @freelancer, body: "Yes, Monday works.")
    assert_equal @freelancer, reply.sender
    assert_equal reply, conversation.messages.last
    assert_equal 2, conversation.messages.count
  end

  test "someone outside the conversation cannot reply" do
    conversation = start.conversation
    assert_raises(ActiveRecord::RecordInvalid) { conversation.reply(sender: @rival, body: "Let me in") }
    assert_equal 1, conversation.messages.count
  end

  test "the other participant of a conversation" do
    conversation = start.conversation
    assert_equal @freelancer, conversation.other_participant(@client)
    assert_equal @client, conversation.other_participant(@freelancer)
  end

  # read state

  test "a new conversation is unread for the recipient only" do
    conversation = start.conversation
    assert conversation.unread_for?(@freelancer)
    assert_not conversation.unread_for?(@client)
  end

  test "marking a conversation as read, and a new reply making it unread again" do
    conversation = start.conversation
    conversation.mark_as_read(@freelancer)
    assert_not conversation.unread_for?(@freelancer)

    travel 1.second do
      conversation.reply(sender: @client, body: "One more thing")
    end
    assert conversation.unread_for?(@freelancer)
  end

  test "a user's own reply does not make the conversation unread for them" do
    conversation = start.conversation
    conversation.mark_as_read(@freelancer)
    travel 1.second do
      conversation.reply(sender: @freelancer, body: "Thanks")
    end
    assert_not conversation.unread_for?(@freelancer)
    assert conversation.unread_for?(@client)
  end

  # trash

  test "moving a conversation to trash hides it only for that user" do
    conversation = start.conversation
    conversation.move_to_trash(@freelancer)
    assert_not_includes Conversation.visible_to(@freelancer), conversation
    assert_includes Conversation.visible_to(@client), conversation
    assert_includes Conversation.involving(@freelancer), conversation
  end

  test "a reply brings a trashed conversation back for everyone" do
    conversation = start.conversation
    conversation.move_to_trash(@freelancer)
    conversation.reply(sender: @client, body: "Following up")
    assert_includes Conversation.visible_to(@freelancer), conversation
  end

  test "a trashed conversation does not count as unread" do
    conversation = start.conversation
    conversation.move_to_trash(@freelancer)
    assert_not conversation.unread_for?(@freelancer)
  end

  # users

  test "a user's conversations are listed newest activity first" do
    older = start(subject: "Older").conversation
    newer = travel(1.minute) { start(subject: "Newer").conversation }
    travel(2.minutes) { older.reply(sender: @freelancer, body: "Bump") }
    assert_equal [older, newer], Conversation.visible_to(@client).to_a
  end

  test "deleting a user removes them from their conversations" do
    conversation = start.conversation
    @freelancer.destroy
    assert_equal [@client], conversation.reload.users.to_a
  end

  test "deleting a user who sent messages keeps the conversation for the other person" do
    conversation = start.conversation
    conversation.reply(sender: @freelancer, body: "Yes, Monday works.")
    @freelancer.destroy
    conversation.reload
    assert_equal 2, conversation.messages.count
    assert_nil conversation.messages.last.sender
    assert_includes Conversation.visible_to(@client), conversation
  end
end
