class CreatePlants < ActiveRecord::Migration[8.0]
    def change
      create_table :plants, id: :string do |t|
        t.string  :family
        t.string  :genus
        t.string  :species
        t.string  :common_name
        t.string  :growth_rate
        t.string  :hardiness_zones
        t.float   :height
        t.float   :width
        t.string  :plant_type   # using "plant_type" instead of "type" to avoid STI conflicts
        t.string  :leaf
        t.string  :flower
        t.string  :ripen
        t.string  :reproduction
        t.text    :soils
        t.string  :ph
        t.text    :preferences
        t.text    :tolerances
        t.text    :habitat
        t.text    :habitat_range
        t.string  :edibility
        t.string  :medicinal
        t.text    :other_uses

        t.timestamps
      end
    end
end
