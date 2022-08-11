class CreateZoneLabels < ActiveRecord::Migration[6.1]
  def change
    create_table :zone_labels do |t|
      t.belongs_to :zone, null: false, foreign_key: true
      t.date :designated_on
      t.string :name

      t.timestamps
    end
  end
end
