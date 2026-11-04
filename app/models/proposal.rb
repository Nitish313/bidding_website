class Proposal < ApplicationRecord
  belongs_to :gig
  belongs_to :user, optional: true

  has_many :solutions, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates_presence_of :name, :bid, :description
  validate :gig_accepts_proposal_from_user, on: :create
  validates :bid, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: Gig::MAX_AMOUNT },
                  allow_nil: true
  validates :name, length: { maximum: 255 }
  after_create :create_notification

  scope :order_by_date, -> { order(created_at: :desc) }
  scope :includes_associations, -> { includes(:gig, :user) }

  def create_notification
    Notification.create(actor_id: self.user.id, receiver_id: self.gig.user.id, action: "proposed", notifiable: self)
  end

  private

  def gig_accepts_proposal_from_user
    return if gig.nil?

    if !gig.open?
      errors.add(:base, "This gig is closed to new proposals.")
    elsif user && gig.proposals.exists?(user_id: user.id)
      errors.add(:base, "You have already submitted a proposal for this gig.")
    end
  end
end
