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

ActiveRecord::Schema[8.1].define(version: 2026_04_10_110400) do
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

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "journal_entry_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["journal_entry_id"], name: "index_comments_on_journal_entry_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "date_proposal_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "date_proposal_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "vote_type"
    t.index ["date_proposal_id"], name: "index_date_proposal_votes_on_date_proposal_id"
    t.index ["user_id"], name: "index_date_proposal_votes_on_user_id"
  end

  create_table "date_proposals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.text "notes"
    t.date "start_date"
    t.string "title"
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trip_id"], name: "index_date_proposals_on_trip_id"
    t.index ["user_id"], name: "index_date_proposals_on_user_id"
  end

  create_table "discussion_posts", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "downvotes_count", default: 0, null: false
    t.string "title", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0, null: false
    t.integer "user_id", null: false
    t.index ["trip_id"], name: "index_discussion_posts_on_trip_id"
    t.index ["user_id"], name: "index_discussion_posts_on_user_id"
  end

  create_table "discussion_replies", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "discussion_post_id", null: false
    t.integer "downvotes_count", default: 0, null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0, null: false
    t.integer "user_id", null: false
    t.index ["discussion_post_id"], name: "index_discussion_replies_on_discussion_post_id"
    t.index ["parent_id"], name: "index_discussion_replies_on_parent_id"
    t.index ["user_id"], name: "index_discussion_replies_on_user_id"
  end

  create_table "discussion_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "votable_id", null: false
    t.string "votable_type", null: false
    t.string "vote_type", null: false
    t.index ["user_id", "votable_type", "votable_id"], name: "index_discussion_votes_uniqueness", unique: true
    t.index ["user_id"], name: "index_discussion_votes_on_user_id"
    t.index ["votable_type", "votable_id"], name: "index_discussion_votes_on_votable_type_and_votable_id"
  end

  create_table "expense_participants", force: :cascade do |t|
    t.decimal "amount_owed", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "expense_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["expense_id", "user_id"], name: "index_expense_participants_on_expense_id_and_user_id", unique: true
    t.index ["expense_id"], name: "index_expense_participants_on_expense_id"
    t.index ["user_id"], name: "index_expense_participants_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "category", default: "other", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "description", null: false
    t.date "expense_date", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.string "location"
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "payer_id", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_expenses_on_category"
    t.index ["expense_date"], name: "index_expenses_on_expense_date"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
    t.index ["trip_id"], name: "index_expenses_on_trip_id"
  end

  create_table "food_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "standard_unit"
    t.string "unit_type"
    t.datetime "updated_at", null: false
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "food_item_id"
    t.string "name"
    t.decimal "quantity"
    t.integer "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["food_item_id"], name: "index_ingredients_on_food_item_id"
    t.index ["recipe_id"], name: "index_ingredients_on_recipe_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.string "role", default: "member", null: false
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["token"], name: "index_invitations_on_token", unique: true
    t.index ["trip_id", "email"], name: "index_invitations_on_trip_id_and_email", unique: true
    t.index ["trip_id"], name: "index_invitations_on_trip_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.date "entry_date"
    t.boolean "favorite"
    t.boolean "global_favorite", default: false
    t.decimal "latitude", precision: 12, scale: 8
    t.string "location"
    t.decimal "longitude", precision: 12, scale: 8
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trip_id"], name: "index_journal_entries_on_trip_id"
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.string "meal_type"
    t.integer "recipe_id", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_meal_plans_on_recipe_id"
    t.index ["trip_id"], name: "index_meal_plans_on_trip_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "parent_recipe_id"
    t.boolean "proposed_for_public", default: false
    t.integer "servings"
    t.string "source_type", default: "trip"
    t.integer "trip_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["source_type"], name: "index_recipes_on_source_type"
    t.index ["trip_id"], name: "index_recipes_on_trip_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shopping_item_comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.datetime "resolved_at"
    t.integer "shopping_list_assignment_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["shopping_list_assignment_id"], name: "index_shopping_item_comments_on_shopping_list_assignment_id"
    t.index ["user_id"], name: "index_shopping_item_comments_on_user_id"
  end

  create_table "shopping_items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "purchased"
    t.decimal "purchased_quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "quantity"
    t.integer "shopping_list_id", null: false
    t.integer "source_id"
    t.string "source_type"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id"], name: "index_shopping_items_on_shopping_list_id"
  end

  create_table "shopping_list_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.decimal "planned_quantity", precision: 10, scale: 2, null: false
    t.integer "position"
    t.decimal "purchased_quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "shopping_list_id", null: false
    t.integer "shopping_requirement_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id"], name: "index_shopping_list_assignments_on_shopping_list_id"
    t.index ["shopping_requirement_id", "shopping_list_id"], name: "index_shopping_assignments_requirement_and_list"
    t.index ["shopping_requirement_id"], name: "index_shopping_list_assignments_on_shopping_requirement_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "position"
    t.string "status"
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_shopping_lists_on_trip_id"
  end

  create_table "shopping_requirements", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "food_item_id"
    t.string "last_synced_signature"
    t.integer "meal_plan_id"
    t.string "name", null: false
    t.text "notes"
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.integer "recipe_id"
    t.string "source_label"
    t.string "source_signature"
    t.string "source_type", null: false
    t.string "sync_status", null: false
    t.datetime "synced_at"
    t.integer "trip_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["food_item_id"], name: "index_shopping_requirements_on_food_item_id"
    t.index ["meal_plan_id"], name: "index_shopping_requirements_on_meal_plan_id"
    t.index ["recipe_id"], name: "index_shopping_requirements_on_recipe_id"
    t.index ["source_type"], name: "index_shopping_requirements_on_source_type"
    t.index ["sync_status"], name: "index_shopping_requirements_on_sync_status"
    t.index ["trip_id", "meal_plan_id"], name: "index_shopping_requirements_on_trip_id_and_meal_plan_id"
    t.index ["trip_id"], name: "index_shopping_requirements_on_trip_id"
  end

  create_table "shopping_sync_runs", force: :cascade do |t|
    t.text "change_summary"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.json "snapshot_payload"
    t.datetime "started_at", null: false
    t.integer "trip_id", null: false
    t.string "undo_token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trip_id"], name: "index_shopping_sync_runs_on_trip_id"
    t.index ["undo_token"], name: "index_shopping_sync_runs_on_undo_token", unique: true
    t.index ["user_id"], name: "index_shopping_sync_runs_on_user_id"
  end

  create_table "trip_attachment_comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "trip_attachment_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trip_attachment_id"], name: "index_trip_attachment_comments_on_trip_attachment_id"
    t.index ["user_id"], name: "index_trip_attachment_comments_on_user_id"
  end

  create_table "trip_attachments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["trip_id"], name: "index_trip_attachments_on_trip_id"
    t.index ["user_id"], name: "index_trip_attachments_on_user_id"
  end

  create_table "trip_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.string "role", default: "member", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["role"], name: "index_trip_members_on_role"
    t.index ["trip_id", "user_id"], name: "index_trip_members_on_trip_id_and_user_id", unique: true
    t.index ["trip_id"], name: "index_trip_members_on_trip_id"
    t.index ["user_id"], name: "index_trip_members_on_user_id"
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "name"
    t.string "series_name"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "user_availabilities", force: :cascade do |t|
    t.string "availability_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.boolean "recurring"
    t.date "start_date"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_availabilities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale", default: "en", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["locale"], name: "index_users_on_locale"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "journal_entries"
  add_foreign_key "comments", "users"
  add_foreign_key "date_proposal_votes", "date_proposals"
  add_foreign_key "date_proposal_votes", "users"
  add_foreign_key "date_proposals", "trips"
  add_foreign_key "date_proposals", "users"
  add_foreign_key "discussion_posts", "trips"
  add_foreign_key "discussion_posts", "users"
  add_foreign_key "discussion_replies", "discussion_posts"
  add_foreign_key "discussion_replies", "discussion_replies", column: "parent_id"
  add_foreign_key "discussion_replies", "users"
  add_foreign_key "discussion_votes", "users"
  add_foreign_key "expense_participants", "expenses"
  add_foreign_key "expense_participants", "users"
  add_foreign_key "expenses", "trips"
  add_foreign_key "expenses", "users", column: "payer_id"
  add_foreign_key "ingredients", "food_items"
  add_foreign_key "ingredients", "recipes"
  add_foreign_key "invitations", "trips"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "journal_entries", "trips"
  add_foreign_key "journal_entries", "users"
  add_foreign_key "meal_plans", "recipes"
  add_foreign_key "meal_plans", "trips"
  add_foreign_key "recipes", "recipes", column: "parent_recipe_id"
  add_foreign_key "recipes", "trips"
  add_foreign_key "recipes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "shopping_item_comments", "shopping_list_assignments"
  add_foreign_key "shopping_item_comments", "users"
  add_foreign_key "shopping_items", "shopping_lists"
  add_foreign_key "shopping_list_assignments", "shopping_lists"
  add_foreign_key "shopping_list_assignments", "shopping_requirements"
  add_foreign_key "shopping_lists", "trips"
  add_foreign_key "shopping_requirements", "food_items"
  add_foreign_key "shopping_requirements", "meal_plans"
  add_foreign_key "shopping_requirements", "recipes"
  add_foreign_key "shopping_requirements", "trips"
  add_foreign_key "shopping_sync_runs", "trips"
  add_foreign_key "shopping_sync_runs", "users"
  add_foreign_key "trip_attachment_comments", "trip_attachments"
  add_foreign_key "trip_attachment_comments", "users"
  add_foreign_key "trip_attachments", "trips"
  add_foreign_key "trip_attachments", "users"
  add_foreign_key "trip_members", "trips"
  add_foreign_key "trip_members", "users"
  add_foreign_key "trips", "users"
  add_foreign_key "user_availabilities", "users"
end
