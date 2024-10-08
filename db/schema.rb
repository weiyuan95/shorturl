# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_09_09_020002) do
  create_table "hashed_url_visits", force: :cascade do |t|
    t.string "ip"
    t.string "country"
    t.string "hashed_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hashed_url"], name: "index_hashed_url_visits_on_hashed_url"
  end

  create_table "urls", force: :cascade do |t|
    t.string "title"
    t.string "target_url"
    t.string "hashed_url"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hashed_url"], name: "index_urls_on_hashed_url", unique: true
    t.index ["salt"], name: "index_urls_on_salt", unique: true
  end
end
