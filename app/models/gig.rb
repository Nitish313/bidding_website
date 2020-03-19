class Gig < ApplicationRecord
  belongs_to :user
  belongs_to :category
  
  has_many :proposals, dependent: :destroy
  has_many :abilities, dependent: :destroy
  has_many :skills, through: :abilities
  has_many :solutions, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  mount_uploaders :attachments, AttachmentUploader
  validates_presence_of :name, :description, :budget, :location
  after_update :create_notification, if: :saved_change_to_awarded_proposal?
  
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_categories, -> { includes(:category) }
  
  def self.search(params)
    if params[:category].present?
      gigs = Gig.where(category_id: params[:category].to_i)
    else
      gigs = Gig.where("name like ? or description like ? or location like ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    end
    gigs
  end

  def skill_list
    self.skills.collect do |skill|
      skill.name
    end.join(", ")
  end

  def self.order_list(sort_order)
    if sort_order == "newest" || sort_order.blank?
      order(created_at: :desc)
    elsif sort_order == "name"
      order(name: :asc)
    else
      order(created_at: :asc)
    end
  end

  def create_notification
    @proposal = Proposal.find_by(id: self.awarded_proposal)
    Notification.create(actor_id: self.user_id, receiver_id: @proposal.user_id, action: "awarded", notifiable: self)
  end
end