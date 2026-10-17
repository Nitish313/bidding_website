# Copies conversations from the mailboxer gem's tables into the app's own tables.
#
# Conversations and messages keep their mailboxer ids, so existing links and
# notifications keep pointing at the same records. Plain SQL is used on purpose:
# the mailboxer gem and its models are removed later, and this migration must keep
# working without them. Rows that were already copied are skipped, so it is safe to
# run again.
class CopyMailboxerData < ActiveRecord::Migration[8.1]
  def up
    copy_conversations
    copy_messages
    copy_participants
    repoint_notifications
  end

  def down
    # Point notifications back at the receipt they used: the app attached the
    # sender's own receipt, which is the one send_message and reply_to_conversation return.
    execute <<~SQL.squish
      UPDATE notifications nt
      JOIN mailboxer_receipts r ON r.notification_id = nt.notifiable_id AND r.receiver_id = nt.actor_id
      SET nt.notifiable_type = 'Mailboxer::Receipt', nt.notifiable_id = r.id
      WHERE nt.notifiable_type = 'Message'
    SQL
    execute "DELETE FROM messages"
    execute "DELETE FROM conversation_participants"
    execute "DELETE FROM conversations"
  end

  private

  # Conversations, with their last activity as the updated time.
  def copy_conversations
    execute <<~SQL.squish
      INSERT INTO conversations (id, subject, created_at, updated_at)
      SELECT c.id, COALESCE(NULLIF(c.subject, ''), '(no subject)'), c.created_at,
             COALESCE((SELECT MAX(n.created_at) FROM mailboxer_notifications n
                       WHERE n.conversation_id = c.id), c.updated_at)
      FROM mailboxer_conversations c
      WHERE NOT EXISTS (SELECT 1 FROM conversations x WHERE x.id = c.id)
    SQL
  end

  # Messages. Senders whose account no longer exists are kept as NULL.
  def copy_messages
    execute <<~SQL.squish
      INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
      SELECT n.id, n.conversation_id,
             (SELECT u.id FROM users u WHERE u.id = n.sender_id AND n.sender_type = 'User'),
             COALESCE(n.body, ''), n.created_at, n.updated_at
      FROM mailboxer_notifications n
      WHERE n.type = 'Mailboxer::Message'
        AND EXISTS (SELECT 1 FROM conversations c WHERE c.id = n.conversation_id)
        AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.id = n.id)
    SQL
  end

  # Participants, one per user per conversation. In mailboxer each user has one
  # receipt per message: a conversation is trashed for a user only when all of their
  # receipts are trashed (or deleted), and it is read up to just before their
  # earliest unread incoming message.
  def copy_participants
    execute <<~SQL.squish
      INSERT INTO conversation_participants
        (conversation_id, user_id, trashed, last_read_at, created_at, updated_at)
      SELECT n.conversation_id, r.receiver_id,
             MIN(r.trashed OR r.deleted),
             COALESCE(MIN(CASE WHEN r.is_read = FALSE AND r.mailbox_type = 'inbox' THEN n.created_at END)
                        - INTERVAL 1 MICROSECOND,
                      MAX(n.created_at)),
             MIN(r.created_at), MAX(r.updated_at)
      FROM mailboxer_receipts r
      JOIN mailboxer_notifications n ON n.id = r.notification_id
      WHERE r.receiver_type = 'User'
        AND n.type = 'Mailboxer::Message'
        AND EXISTS (SELECT 1 FROM users u WHERE u.id = r.receiver_id)
        AND EXISTS (SELECT 1 FROM conversations c WHERE c.id = n.conversation_id)
        AND NOT EXISTS (SELECT 1 FROM conversation_participants p
                        WHERE p.conversation_id = n.conversation_id AND p.user_id = r.receiver_id)
      GROUP BY n.conversation_id, r.receiver_id
    SQL
  end

  # Notifications pointed at a mailboxer receipt; point them at its message instead.
  def repoint_notifications
    execute <<~SQL.squish
      UPDATE notifications nt
      JOIN mailboxer_receipts r ON r.id = nt.notifiable_id
      SET nt.notifiable_type = 'Message', nt.notifiable_id = r.notification_id
      WHERE nt.notifiable_type = 'Mailboxer::Receipt'
        AND EXISTS (SELECT 1 FROM messages m WHERE m.id = r.notification_id)
    SQL
  end
end
