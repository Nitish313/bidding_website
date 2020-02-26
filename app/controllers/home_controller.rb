class HomeController < ApplicationController
  def index
    @freelancers = User.where(role: "Freelancer", activated: true).paginate(page: params[:page], per_page: 20)
  end
end