class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :unread_counts, only: :show, if: :logged_in?
  before_action :unread_notification_counts, if: :logged_in?
  before_action :tag_error_reports_with_user, if: :logged_in?

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
    @user = current_user.admin? ? User.find(params.expect(:user_id)) : current_user
  end

  # Admins may view other users' conversations and notifications, but only act as themselves.
  def own_account_only
    return if current_user?(@user)

    flash[:danger] = "You can only do this from your own account."
    redirect_to current_user
  end

  def unread_counts
    @unread_counts = Conversation.unread_by(current_user).count
  end

  def unread_notification_counts
    @unread_notification_counts = 0
    current_user.notifications.each do |notification|
      @unread_notification_counts += 1 unless notification.is_read?
    end
  end

  private

  # Lets an error report say which account hit it, by id only.
  def tag_error_reports_with_user
    Sentry.set_user(id: current_user.id)
  end
end
