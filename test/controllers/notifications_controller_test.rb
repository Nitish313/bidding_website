require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @client = users(:client)
    @notification = notifications(:proposal_received)
  end

  test "the notification list requires login" do
    get user_notifications_path(@client)
    assert_redirected_to login_path
  end

  test "a user sees their own notifications" do
    log_in_as(@client)
    get user_notifications_path(@client)
    assert_response :success
    assert_select "a", text: proposals(:landing_page_bid).name
  end

  test "a user marks their notification as read" do
    log_in_as(@client)
    post mark_as_read_user_notification_path(@client, @notification)
    assert_redirected_to user_notifications_path(@client)
    assert_predicate @notification.reload, :is_read?
  end

  test "a user deletes their notification" do
    log_in_as(@client)
    assert_difference "Notification.count", -1 do
      delete user_notification_path(@client, @notification)
    end
    assert_redirected_to user_notifications_path(@client)
  end

  test "a user cannot touch someone else's notification" do
    log_in_as(users(:freelancer))
    assert_raises(ActiveRecord::RecordNotFound) do
      post mark_as_read_user_notification_path(users(:freelancer), @notification)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      delete user_notification_path(users(:freelancer), @notification)
    end
  end

  test "an admin can read another user's notifications without controls to act as them" do
    log_in_as(@admin)
    get user_notifications_path(@client)
    assert_response :success
    assert_select "a", text: proposals(:landing_page_bid).name
    assert_select "a", text: "Mark as read", count: 0
    assert_select "a", text: "Delete this notification", count: 0
  end

  test "an admin cannot mark another user's notification as read" do
    log_in_as(@admin)
    post mark_as_read_user_notification_path(@client, @notification)
    assert_redirected_to user_path(@admin)
    assert_not @notification.reload.is_read?
  end

  test "an admin cannot delete another user's notification" do
    log_in_as(@admin)
    assert_no_difference "Notification.count" do
      delete user_notification_path(@client, @notification)
    end
    assert_redirected_to user_path(@admin)
  end
end
