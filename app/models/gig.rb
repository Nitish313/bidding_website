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
  # Amounts are whole currency units; the cap keeps them inside the integer column.
  MAX_AMOUNT = 1_000_000_000
  validates :budget, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_AMOUNT },
                     allow_nil: true
  validates :name, :location, length: { maximum: 255 }
  MAX_SKILLS = 20
  validates :skill_list, length: { maximum: 1000 }
  validate :skill_names_fit
  validate :award_is_one_of_this_gigs_proposals, if: :awarded_proposal_changed?
  after_update :create_notification, if: :saved_change_to_awarded_proposal?
  after_create :create_skills
  after_update :create_skills

  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_categories, -> { includes(:category) }

  SKILL_SEPARATORS = /[,;\r\n]+/

  def self.search(params)
    params = normalize_search_params(params)
    if params[:category].present?
      where(category_id: params[:category].to_i)
    elsif params[:search].present?
      term = "%#{sanitize_sql_like(params[:search].strip)}%"
      where("name like :term or description like :term or location like :term or skill_list like :term", term: term)
    else
      all
    end
  end

  def self.normalize_search_params(params)
    case params
    when nil then {}
    when Hash then params.with_indifferent_access
    else raise ArgumentError, "search params must be a Hash, got #{params.class}"
    end
  end
  private_class_method :normalize_search_params

  def skill_names
    skill_list.to_s.split(SKILL_SEPARATORS).map { |s| s.squish.downcase }.compact_blank.uniq
  end

  def create_skills
    self.skills = skill_names.map { |name| Skill.find_or_create_by(name: name) }
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

  private

  def skill_names_fit
    names = skill_names
    errors.add(:skill_list, "can list at most #{MAX_SKILLS} skills") if names.size > MAX_SKILLS
    errors.add(:skill_list, "contains a skill longer than 255 characters") if names.any? { |name| name.length > 255 }
  end

  def award_is_one_of_this_gigs_proposals
    if awarded_proposal_was.present?
      errors.add(:awarded_proposal, "can't be changed once the gig is awarded")
    elsif !proposals.exists?(id: awarded_proposal)
      errors.add(:awarded_proposal, "must be one of this gig's proposals")
    end
  end
end
