require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @client = users(:client)
    @freelancer = users(:freelancer)
    @conversation = Conversation.start(sender: @client, recipient: @freelancer, subject: "Landing page", body: "Can you start Monday?").conversation
  end

  def reply(as_user_id, body: "Yes, Monday works.")
    post user_conversation_messages_path(as_user_id, @conversation), params: { body: body }
  end

  test "replying redirects to login when logged out and sends nothing" do
    assert_no_difference "@conversation.messages.count" do
      reply(@freelancer.id)
    end
    assert_redirected_to login_path
  end

  test "a participant replies to the conversation" do
    log_in_as(@freelancer)
    assert_difference "@conversation.messages.count", 1 do
      reply(@freelancer.id)
    end
    assert_redirected_to user_conversation_path(@freelancer, @conversation)
    assert_equal @freelancer, @conversation.messages.last.sender
  end

  test "a reply without a body is refused" do
    log_in_as(@freelancer)
    assert_no_difference "@conversation.messages.count" do
      reply(@freelancer.id, body: "")
    end
    assert_redirected_to user_conversations_path(@freelancer)
  end

  test "a user outside the conversation cannot reply" do
    log_in_as(users(:inactive).tap { |u| u.update_columns(activated: true) })
    assert_raises(ActiveRecord::RecordNotFound) { reply(users(:inactive).id) }
    assert_equal 1, @conversation.messages.count
  end

  test "a user cannot reply as someone else by changing the user id in the URL" do
    outsider = users(:inactive).tap { |u| u.update_columns(activated: true) }
    log_in_as(outsider)
    assert_raises(ActiveRecord::RecordNotFound) { reply(@freelancer.id) }
    assert_equal 1, @conversation.messages.count
  end

  test "an admin cannot reply as another user" do
    log_in_as(users(:admin))
    assert_no_difference "@conversation.messages.count" do
      reply(@freelancer.id)
    end
    assert_redirected_to user_path(users(:admin))
    assert_equal "You can only do this from your own account.", flash[:danger]
  end

  test "an admin replies in their own conversation" do
    admin = users(:admin)
    conversation = Conversation.start(sender: admin, recipient: @client, subject: "Profile", body: "Please update your profile.").conversation
    log_in_as(admin)
    assert_difference "conversation.messages.count", 1 do
      post user_conversation_messages_path(admin, conversation), params: { body: "Thanks." }
    end
    assert_equal admin, conversation.messages.last.sender
  end

  test "replying notifies the other participant" do
    log_in_as(@freelancer)
    assert_difference "Notification.where(action: 'sent a message').count", 1 do
      reply(@freelancer.id)
    end
    assert_equal @client.id, Notification.last.receiver_id
  end

  test "a reply that is too long is refused with a message" do
    log_in_as(@freelancer)
    assert_no_difference "@conversation.messages.count" do
      reply(@freelancer.id, body: "x" * 32_001)
    end
    assert_redirected_to user_conversation_path(@freelancer, @conversation)
    assert_match "Body is too long", flash[:danger]
  end
end
