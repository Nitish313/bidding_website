class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  def redirect_to_desired(user)
    if user.role == "Freelancer"
      redirect_to freelancer_path(user)
    elsif user.role == "Client"
      redirect_to client_path(user)
    else
      redirect_to root_path
    end
  end
end
