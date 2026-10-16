require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @client = users(:client)
    @freelancer = users(:freelancer)
    @conversation = @client.send_message(@freelancer, "Can you start Monday?", "Landing page").conversation
  end

  def start_conversation(as_user, receiver_id:, subject: "Hello", body: "Are you available?")
    post user_conversations_path(as_user), params: { receiver_id: receiver_id, subject: subject, body: body }
  end

  # viewing

  test "the conversation list requires login" do
    get user_conversations_path(@client)
    assert_redirected_to login_path
  end

  test "a user sees their own conversations" do
    log_in_as(@freelancer)
    get user_conversations_path(@freelancer)
    assert_response :success
    assert_select "a", text: "Landing page"
  end

  test "a non-admin who puts another user's id in the URL sees only their own conversations" do
    log_in_as(users(:rival))
    get user_conversations_path(@freelancer)
    assert_response :success
    assert_select "a", text: "Landing page", count: 0
  end

  test "a participant sees the reply form on their conversation" do
    log_in_as(@freelancer)
    get user_conversation_path(@freelancer, @conversation)
    assert_response :success
    assert_select "form[action=?]", user_conversation_messages_path(@freelancer, @conversation)
  end

  test "a user outside the conversation cannot open it" do
    log_in_as(users(:rival))
    assert_raises(ActiveRecord::RecordNotFound) { get user_conversation_path(users(:rival), @conversation) }
  end

  test "an admin can read another user's conversations" do
    log_in_as(@admin)
    get user_conversations_path(@freelancer)
    assert_response :success
    assert_select "a", text: "Landing page"
    get user_conversation_path(@freelancer, @conversation)
    assert_response :success
    assert_select "div", text: /Can you start Monday\?/
  end

  test "an admin reading another user's conversations gets no controls to act as them" do
    log_in_as(@admin)
    get user_conversations_path(@freelancer)
    assert_select "a", text: "New Conversation", count: 0
    assert_select "a", text: "Mark as read", count: 0
    assert_select "a", text: "Delete this conversation", count: 0
    get user_conversation_path(@freelancer, @conversation)
    assert_select "form", count: 0
  end

  # starting a conversation

  test "a user starts a conversation and the receiver is notified" do
    log_in_as(@freelancer)
    assert_difference "Mailboxer::Conversation.count", 1 do
      assert_difference "Notification.where(action: 'started a conversation').count", 1 do
        start_conversation(@freelancer, receiver_id: users(:rival).id)
      end
    end
    conversation = Mailboxer::Conversation.last
    assert_redirected_to user_conversation_path(@freelancer, conversation)
    assert_equal @freelancer, conversation.originator
    assert_equal users(:rival).id, Notification.last.receiver_id
  end

  test "starting a conversation without a subject or body is refused" do
    log_in_as(@freelancer)
    assert_no_difference "Mailboxer::Conversation.count" do
      start_conversation(@freelancer, receiver_id: @client.id, subject: "")
      start_conversation(@freelancer, receiver_id: @client.id, body: "")
    end
    assert_redirected_to new_user_conversation_path(@freelancer)
  end

  test "a user cannot start a conversation with themselves" do
    log_in_as(@freelancer)
    assert_no_difference "Mailboxer::Conversation.count" do
      start_conversation(@freelancer, receiver_id: @freelancer.id)
    end
    assert_redirected_to new_user_conversation_path(@freelancer)
    assert_equal "You can't start a conversation with yourself.", flash[:danger]
  end

  test "starting a conversation needs exactly one receiver" do
    log_in_as(@freelancer)
    assert_no_difference "Mailboxer::Conversation.count" do
      assert_raises(ActionController::ParameterMissing) do
        post user_conversations_path(@freelancer), params: { subject: "Hello", body: "Are you available?" }
      end
      assert_raises(ActionController::ParameterMissing) do
        start_conversation(@freelancer, receiver_id: [@client.id, users(:rival).id])
      end
    end
  end

  test "a list of receivers cannot be used to message yourself" do
    log_in_as(@freelancer)
    assert_no_difference "Mailboxer::Conversation.count" do
      assert_raises(ActionController::ParameterMissing) do
        start_conversation(@freelancer, receiver_id: [@freelancer.id])
      end
    end
  end

  test "starting a conversation with a missing user raises not found" do
    log_in_as(@freelancer)
    assert_raises(ActiveRecord::RecordNotFound) { start_conversation(@freelancer, receiver_id: 0) }
  end

  test "an admin cannot start a conversation as another user" do
    log_in_as(@admin)
    assert_no_difference "Mailboxer::Conversation.count" do
      start_conversation(@freelancer, receiver_id: @client.id)
    end
    assert_redirected_to user_path(@admin)
    assert_equal "You can only do this from your own account.", flash[:danger]
  end

  test "an admin starts a conversation from their own account" do
    log_in_as(@admin)
    assert_difference "Mailboxer::Conversation.count", 1 do
      start_conversation(@admin, receiver_id: @client.id)
    end
    assert_equal @admin, Mailboxer::Conversation.last.originator
  end

  # mark as read and delete

  test "a participant marks a conversation as read" do
    log_in_as(@freelancer)
    assert @conversation.is_unread?(@freelancer)
    post mark_as_read_user_conversation_path(@freelancer, @conversation)
    assert_redirected_to user_conversations_path(@freelancer)
    assert_not @conversation.reload.is_unread?(@freelancer)
  end

  test "an admin cannot mark another user's conversation as read" do
    log_in_as(@admin)
    post mark_as_read_user_conversation_path(@freelancer, @conversation)
    assert_redirected_to user_path(@admin)
    assert @conversation.reload.is_unread?(@freelancer)
  end

  # deleting moves the conversation to the deleting user's trash only

  def trash_as(user)
    log_in_as(user)
    delete user_conversation_path(user, @conversation)
  end

  test "deleting a conversation keeps it in the database" do
    assert_no_difference "Mailboxer::Conversation.count" do
      trash_as(@freelancer)
    end
    assert_redirected_to user_conversations_path(@freelancer)
    assert_equal "Conversation moved to trash.", flash[:success]
  end

  test "deleting a conversation moves it to trash for the person who deleted it" do
    trash_as(@freelancer)
    assert @conversation.reload.is_completely_trashed?(@freelancer)
    get user_conversations_path(@freelancer)
    assert_select "a", text: "Landing page", count: 0
  end

  test "deleting a conversation leaves it untouched for the other participant" do
    trash_as(@freelancer)
    delete logout_path
    assert_not @conversation.reload.is_trashed?(@client)
    log_in_as(@client)
    get user_conversations_path(@client)
    assert_select "a", text: "Landing page"
    get user_conversation_path(@client, @conversation)
    assert_select "div", text: /Can you start Monday\?/
  end

  test "a trashed conversation comes back when the other participant replies" do
    trash_as(@freelancer)
    @client.reply_to_conversation(@conversation, "Following up on Monday.")
    get user_conversations_path(@freelancer)
    assert_select "a", text: "Landing page"
    get user_conversation_path(@freelancer, @conversation)
    assert_select "div", text: /Following up on Monday\./
  end

  test "a trashed conversation no longer counts as unread" do
    log_in_as(@freelancer)
    get user_path(@freelancer)
    assert_select "span.badge", text: "1"
    delete user_conversation_path(@freelancer, @conversation)
    get user_path(@freelancer)
    assert_select "span.badge", text: ""
  end

  test "when both participants delete it, it is hidden for both and still kept" do
    trash_as(@freelancer)
    delete logout_path
    assert_no_difference "Mailboxer::Conversation.count" do
      trash_as(@client)
    end
    get user_conversations_path(@client)
    assert_select "a", text: "Landing page", count: 0
  end

  test "a user outside the conversation cannot delete it" do
    log_in_as(users(:rival))
    assert_raises(ActiveRecord::RecordNotFound) do
      delete user_conversation_path(users(:rival), @conversation)
    end
    assert_not @conversation.reload.is_trashed?(@freelancer)
  end

  test "an admin cannot delete another user's conversation" do
    log_in_as(@admin)
    assert_no_difference "Mailboxer::Conversation.count" do
      delete user_conversation_path(@freelancer, @conversation)
    end
    assert_redirected_to user_path(@admin)
  end

  test "the new conversation form lists everyone except the user" do
    log_in_as(@freelancer)
    get new_user_conversation_path(@freelancer)
    assert_response :success
    assert_select "select[name=receiver_id] option", text: "Carl Client"
    assert_select "select[name=receiver_id] option", text: "Fiona Freelancer", count: 0
  end
end
