class NotificationsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user
  before_action :own_account_only, only: [:mark_as_read, :destroy]
  def index
    @notifications = @user.notifications.order_by_date.includes_associations
  end

  def destroy
    @notification = @user.notifications.find(params.expect(:id))
    @notification.destroy
    flash[:success] = "Notification deleted successfully."
    redirect_to user_notifications_path
  end

  def mark_as_read
    @notification = @user.notifications.find(params.expect(:id))
    @notification.update(is_read: true)
    flash[:success] = "This notification is marked as read."
    redirect_to user_notifications_path
  end
end