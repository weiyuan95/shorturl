class CreateUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :urls do |t|
      t.string :title
      t.string :target_url
      t.string :hashed_url
      t.string :salt

      t.timestamps
    end

    add_index :urls, :hashed_url, unique: true
    add_index :urls, :salt, unique: true
  end
end
