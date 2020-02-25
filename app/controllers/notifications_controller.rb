class NotificationsController < ApplicationController
  before_action :logged_in_user
  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy
    flash[:success] = "Notification deleted successfully."
    redirect_to notifications_path
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.update(is_read: true)
    flash[:success] = "This notification is marked as read."
    redirect_to notifications_path
  end
end