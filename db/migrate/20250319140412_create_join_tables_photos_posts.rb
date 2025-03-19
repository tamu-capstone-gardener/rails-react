class CreateJoinTablesPhotosPosts < ActiveRecord::Migration[8.0]
  def change
    create_join_table :photos, :posts do |t|
      t.index [ :photo_id, :post_id ]
      t.index [ :post_id, :photo_id ]
    end
  end
end
