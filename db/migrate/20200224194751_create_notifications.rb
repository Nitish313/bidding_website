class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.integer :actor_id
      t.integer :receiver_id
      t.string :action
      t.integer :notifiable_id
      t.string :notifiable_type
      t.boolean :is_read, default: false

      t.timestamps
    end
  end
end
