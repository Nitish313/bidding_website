class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update, :destroy]
  before_action :proper_user, only: [:edit, :update]
  before_action :admin_user, only: :destroy
  before_action :unread_counts, only: :show, if: :logged_in?
  before_action :unread_notification_counts, if: :logged_in?
  before_action :correct_user, only: [:show], if: :logged_in?
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  def new
    @user = User.new
  end

  def index
    @users = User.where(activated: true).paginate(page: params[:page])
  end

  def show
    redirect_to root_path and return unless @user.activated?
  end

  def create
    @user = User.new(user_params)   
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account"
      redirect_to letter_opener_web_path
    else
      render 'new'
    end
  end

  def edit 
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "User deleted!"
    redirect_to users_path
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation,:education, :experience, :industry, :role, :profile_picture)
    end

    def set_user
      @user = User.find(params[:id])
    end

    def proper_user
      @user = User.find(params[:id])
      redirect_to root_path unless (current_user?(@user) || current_user.admin?)
    end

    def correct_user
      if current_user.admin?
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end

    def admin_user
      redirect_to root_path unless current_user.admin?
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
