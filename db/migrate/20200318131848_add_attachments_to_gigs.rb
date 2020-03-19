class AddAttachmentsToGigs < ActiveRecord::Migration[5.2]
  def change
    add_column :gigs, :attachments, :json
  end
end
