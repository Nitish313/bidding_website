class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :education
      t.integer :experience
      t.string :industry
      t.binary :profile_picture
      t.string :role

      t.timestamps
    end
  end
end
