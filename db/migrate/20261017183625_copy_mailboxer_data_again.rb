require_relative "20261017175700_copy_mailboxer_data"

# Copies anything sent through mailboxer since the first copy, right before the app
# switches to its own conversation tables. The copy skips rows it already has.
class CopyMailboxerDataAgain < ActiveRecord::Migration[8.1]
  def up
    CopyMailboxerData.new.up
  end

  def down
    # Nothing to undo: the original copy migration removes the copied rows.
  end
end
