class CreateSolutions < ActiveRecord::Migration[5.2]
  def change
    create_table :solutions do |t|
      t.string :name
      t.string :attachment_1
      t.string :attachment_2
      t.string :attachment_3
      t.references :gig, foreign_key: true
      t.references :proposal, foreign_key: true

      t.timestamps
    end
  end
end
