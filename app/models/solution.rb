class Solution < ApplicationRecord
  mount_uploader :attachment_1, AttachmentUploader
  mount_uploader :attachment_2, AttachmentUploader
  mount_uploader :attachment_3, AttachmentUploader

  validates :name, :attachment_1, presence: true
  validates :name, length: { maximum: 255 }

  belongs_to :gig
  belongs_to :proposal
end
