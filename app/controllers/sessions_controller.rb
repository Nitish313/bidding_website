class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: session_params[:email].to_s.downcase)
    if user && user.authenticate(session_params[:password].to_s)
      if user.activated?
        log_in user
        session_params[:remember_me] == '1' ? remember(user) : forget(user)
        redirect_to(user)
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      flash.now[:danger] = "Invalid login credentials!"
      render 'new'
    end
  end

  def destroy 
    log_out if logged_in?
    flash[:success] = "Logged out successfully"
    redirect_to root_path
  end

  private

  def session_params
    @session_params ||= params.expect(session: [:email, :password, :remember_me])
  end
end
