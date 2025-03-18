class CreatePhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :photos, id: :string do |t|
      t.timestamps

      t.timestamp :timestamp, null: false
      t.references :plant_module, null: false, foreign_key: true, type: :string
      t.string :url
    end
  end
end
