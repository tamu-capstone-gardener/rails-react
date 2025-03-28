class AddFoliagePhSplitPollinatorsPfafToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :foliage, :string
    add_column :plants, :ph_split, :string
    add_column :plants, :pollinators, :string
    add_column :plants, :pfaf, :string
  end
end
