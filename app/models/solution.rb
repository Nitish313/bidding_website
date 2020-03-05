class Solution < ApplicationRecord
  mount_uploader :attachment_1, AttachmentUploader
  mount_uploader :attachment_2, AttachmentUploader
  mount_uploader :attachment_3, AttachmentUploader
  
  validates_presence_of :name, :attachment_1

  belongs_to :gig
  belongs_to :proposal
end
