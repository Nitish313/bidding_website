class AddNameToProposals < ActiveRecord::Migration[5.2]
  def change
    add_column :proposals, :name, :string, null: false
  end
end
