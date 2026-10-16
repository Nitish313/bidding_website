class UsersController < ApplicationController
  before_action :logged_in_user, only: [:edit, :update, :destroy, :deactivate, :activate]
  before_action :proper_user, only: [:edit, :update]
  before_action :admin_user, only: [:destroy, :deactivate, :activate]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :deactivate, :activate]
  def new
    @user = User.new
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def show
    redirect_to root_path and return unless @user.activated?
  end

  def create
    @user = User.new(user_params)   
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account"
      # In development, emails are only viewable through letter_opener_web.
      redirect_to Rails.env.development? ? letter_opener_web_path : root_url
    else
      render 'new'
    end
  end

  def edit 
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def deactivate
    if current_user?(@user)
      flash[:danger] = "You can't deactivate your own account"
    else
      @user.deactivate
      flash[:success] = 'User deactivated'
    end
    redirect_to users_path
  end

  def activate
    @user.activate
    flash[:success] = 'User activated'
    redirect_to users_path
  end

  def destroy
    if current_user?(@user)
      flash[:danger] = "You can't delete your own account"
    else
      @user.destroy
      flash[:success] = "User deleted!"
    end
    redirect_to users_path
  end

  private

    def user_params
      params.expect(user: [:name, :email, :password, :password_confirmation, :education, :experience, :industry, :role, :profile_picture])
    end

    def set_user
      @user = User.find(params.expect(:id))
    end

    def proper_user
      @user = User.find(params.expect(:id))
      redirect_to root_path unless owner_or_admin?(@user)
    end

    def admin_user
      redirect_to root_path unless current_user.admin?
    end
end
