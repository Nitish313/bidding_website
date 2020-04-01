class AddSkillListToGigs < ActiveRecord::Migration[5.2]
  def change
    add_column :gigs, :skill_list, :text
  end
end
