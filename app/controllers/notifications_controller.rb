class NotificationsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user
  def index
    @notifications = @user.notifications.order(created_at: :desc)
  end

  def destroy
    @notification = @user.notifications.find(params[:id])
    @notification.destroy
    flash[:success] = "Notification deleted successfully."
    redirect_to user_notifications_path
  end

  def mark_as_read
    @notification = @user.notifications.find(params[:id])
    @notification.update(is_read: true)
    flash[:success] = "This notification is marked as read."
    redirect_to user_notifications_path
  end
end