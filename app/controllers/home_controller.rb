class HomeController < ApplicationController
  def index
    @freelancers = User.activated_freelancers.paginate(page: params[:page], per_page: 20)
  end
end