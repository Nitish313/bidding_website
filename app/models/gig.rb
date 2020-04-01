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
  after_create :create_skills
  after_update :create_skills
  
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_categories, -> { includes(:category) }
  
  def self.search(params)
    if params[:category].present?
      gigs = Gig.where(category_id: params[:category].to_i)
    else
      gigs = Gig.where("name like ? or description like ? or location like ? or skill_list like ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    end
    gigs
  end

  def create_skills
    skill_names = self.skill_list.split(",").collect{ |s| s.strip.downcase }.uniq
    new_or_found_skills = skill_names.collect{ |name| Skill.find_or_create_by(name: name) }
    self.skills = new_or_found_skills
  end

=begin  def skill_list=(skills_string)
    skill_names = skills_string.split(",").collect{ |s| s.strip.downcase }.uniq
    new_or_found_skills = skill_names.collect{ |name| Skill.find_or_create_by(name: name) }
    self.skills = new_or_found_skills
  end
=end
=begin  def skill_list
    skill_lists = self.skills.collect do |skill|
      skill.name
    end.join(", ")
    self.skill_list = skill_lists
  end
=end
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