class Solution < ApplicationRecord
  mount_uploader :attachment_1, AttachmentUploader
  mount_uploader :attachment_2, AttachmentUploader
  mount_uploader :attachment_3, AttachmentUploader
  validates :name, presence: true
  validates :attachment_1, presence: true

  belongs_to :gig
  belongs_to :proposal
end
