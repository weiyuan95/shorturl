class CreateHashedUrlVisits < ActiveRecord::Migration[7.2]
  def change
    create_table :hashed_url_visits do |t|
      t.string :ip
      t.string :country
      t.string :hashed_url

      t.timestamps
    end

    add_index :hashed_url_visits, :hashed_url
  end
end
