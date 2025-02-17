# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :full_name, null: false
      t.string :uid, null: false
      t.string :username, null: false
      t.string :provider, null: false, default: "google_oauth2"
      t.string :avatar_url, null: false
      t.timestamps null: false
    end
    add_index :users, :email, unique: true
    add_index :users, :uid, unique: true
    add_index :users, :username, unique: true
  end
end
