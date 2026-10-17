# Messaging now uses the app's own conversations, conversation_participants and
# messages tables (copied over by the CopyMailboxerData migrations), so the mailboxer
# gem's tables can go. This cannot be rolled back: the gem is removed too, and the
# copied data lives in the new tables.
class DropMailboxerTables < ActiveRecord::Migration[8.1]
  def up
    # Notifications still pointing at mailboxer records could not be repointed by the
    # copy, and would crash the notifications page once the gem is gone.
    execute "DELETE FROM notifications WHERE notifiable_type LIKE 'Mailboxer::%'"

    drop_table :mailboxer_conversation_opt_outs
    drop_table :mailboxer_receipts
    drop_table :mailboxer_notifications
    drop_table :mailboxer_conversations
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "mailboxer and its tables were removed; messaging uses the in-app tables"
  end
end
