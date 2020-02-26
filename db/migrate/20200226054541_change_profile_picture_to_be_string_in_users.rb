class ChangeProfilePictureToBeStringInUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :profile_picture, :string
  end

  def down
    change_column :users, :profile_picture, :binary
  end
end
