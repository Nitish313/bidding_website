require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @client = users(:client)
    @freelancer = users(:freelancer)
    @conversation = @client.send_message(@freelancer, "Can you start Monday?", "Landing page").conversation
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
end
