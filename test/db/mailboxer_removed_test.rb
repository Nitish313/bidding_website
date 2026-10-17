require "test_helper"

# Messaging runs on the app's own Conversation, ConversationParticipant and Message
# models; the mailboxer gem and its tables are gone.
class MailboxerRemovedTest < ActiveSupport::TestCase
  test "the mailboxer gem is no longer loaded" do
    assert_not defined?(Mailboxer), "Mailboxer is still loaded"
    assert_not_respond_to users(:client), :mailbox
  end

  test "the mailboxer tables are dropped" do
    connection = ActiveRecord::Base.connection
    %w[mailboxer_conversations mailboxer_notifications mailboxer_receipts mailboxer_conversation_opt_outs].each do |table|
      assert_not connection.table_exists?(table), "#{table} still exists"
    end
  end
end
