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

ActiveRecord::Schema[8.1].define(version: 2026_03_15_204258) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at", null: false
    t.integer "max_tickets_per_order", default: 10
    t.string "name", null: false
    t.integer "organizer_id", null: false
    t.integer "seat_selection_mode", default: 0, null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "venue_id", null: false
    t.integer "waiting_room_admission_minutes", default: 10
    t.integer "waiting_room_capacity", default: 50
    t.boolean "waiting_room_enabled", default: false
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
    t.index ["status"], name: "index_events_on_status"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_id", null: false
    t.integer "quantity", null: false
    t.integer "ticket_type_id", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["ticket_type_id"], name: "index_order_items_on_ticket_type_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "reference_number", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_orders_on_event_id"
    t.index ["reference_number"], name: "index_orders_on_reference_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "seat_holds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "expires_at", null: false
    t.integer "seat_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_seat_holds_on_event_id"
    t.index ["expires_at"], name: "index_seat_holds_on_expires_at"
    t.index ["seat_id", "event_id"], name: "index_seat_holds_on_seat_and_event", unique: true
    t.index ["seat_id"], name: "index_seat_holds_on_seat_id"
    t.index ["user_id", "event_id"], name: "index_seat_holds_on_user_and_event"
    t.index ["user_id"], name: "index_seat_holds_on_user_id"
  end

  create_table "seats", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "label"
    t.string "row_label", null: false
    t.integer "seat_number", null: false
    t.integer "section_id", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "row_label", "seat_number"], name: "idx_seats_unique_in_section", unique: true
    t.index ["section_id"], name: "index_seats_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "section_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "venue_id", null: false
    t.index ["venue_id", "name"], name: "index_sections_on_venue_id_and_name", unique: true
    t.index ["venue_id"], name: "index_sections_on_venue_id"
  end

  create_table "ticket_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "event_id", null: false
    t.integer "max_per_order", default: 10
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "quantity", null: false
    t.datetime "sale_ends_at"
    t.datetime "sale_starts_at"
    t.integer "section_id"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_ticket_types_on_event_id"
    t.index ["section_id"], name: "index_ticket_types_on_section_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "attendee_email"
    t.string "attendee_name"
    t.string "barcode", null: false
    t.datetime "created_at", null: false
    t.integer "order_item_id", null: false
    t.string "row_label"
    t.integer "seat_id"
    t.integer "seat_number"
    t.string "section_name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_tickets_on_barcode", unique: true
    t.index ["order_item_id"], name: "index_tickets_on_order_item_id"
    t.index ["seat_id"], name: "index_tickets_on_seat_id"
    t.index ["status"], name: "index_tickets_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.text "address", null: false
    t.integer "capacity"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.text "description"
    t.string "name", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_venues_on_created_by_id"
  end

  create_table "waiting_room_entries", force: :cascade do |t|
    t.string "admission_token"
    t.datetime "admitted_at"
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "expires_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["admission_token"], name: "index_waiting_room_entries_on_admission_token", unique: true
    t.index ["event_id", "user_id"], name: "index_waiting_room_entries_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_waiting_room_entries_on_event_id"
    t.index ["status"], name: "index_waiting_room_entries_on_status"
    t.index ["user_id"], name: "index_waiting_room_entries_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "events", "venues"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "ticket_types"
  add_foreign_key "orders", "events"
  add_foreign_key "orders", "users"
  add_foreign_key "seat_holds", "events"
  add_foreign_key "seat_holds", "seats"
  add_foreign_key "seat_holds", "users"
  add_foreign_key "seats", "sections"
  add_foreign_key "sections", "venues"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "ticket_types", "sections"
  add_foreign_key "tickets", "order_items"
  add_foreign_key "tickets", "seats"
  add_foreign_key "venues", "users", column: "created_by_id"
  add_foreign_key "waiting_room_entries", "events"
  add_foreign_key "waiting_room_entries", "users"
end
