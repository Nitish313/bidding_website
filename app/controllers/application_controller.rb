class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :unread_counts, only: :show, if: :logged_in?
  before_action :unread_notification_counts, if: :logged_in?

  # True when the logged-in user is the given owner, or an admin.
  def owner_or_admin?(owner)
    current_user == owner || current_user.admin?
  end

  def logged_in_user
    unless logged_in?
      flash[:danger] = "Please log in first!"
      redirect_to login_path
    end
  end

  def correct_user
    if current_user.admin?
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
  end

  # Admins may view other users' conversations and notifications, but only act as themselves.
  def own_account_only
    return if current_user?(@user)

    flash[:danger] = "You can only do this from your own account."
    redirect_to current_user
  end

  def unread_counts
    @unread_counts = 0
    current_user.mailbox.conversations.each do |conversation|
      @unread_counts+=1 if conversation.is_unread?(current_user)
    end
  end

  def unread_notification_counts
    @unread_notification_counts = 0
    current_user.notifications.each do |notification|
      @unread_notification_counts+=1 if !notification.is_read?
    end
  end
end
