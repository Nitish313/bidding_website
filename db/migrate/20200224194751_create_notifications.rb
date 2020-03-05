class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.integer :actor_id, null: false
      t.integer :receiver_id, null: false
      t.string :action, null: false
      t.integer :notifiable_id, null: false
      t.string :notifiable_type, null: false
      t.boolean :is_read, default: false

      t.timestamps
    end
  end
end
