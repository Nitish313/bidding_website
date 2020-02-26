class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

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
end
