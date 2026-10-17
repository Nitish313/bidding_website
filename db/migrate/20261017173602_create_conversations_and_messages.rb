# In-app messaging, replacing the mailboxer gem's tables.
class CreateConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :subject, null: false
      t.timestamps
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at
      t.boolean :trashed, null: false, default: false
      t.timestamps
      t.index [:conversation_id, :user_id], unique: true
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      # A deleted user's messages stay in the conversation without a sender.
      t.references :sender, foreign_key: { to_table: :users, on_delete: :nullify }
      t.text :body, null: false
      t.timestamps
    end
  end
end
