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

ActiveRecord::Schema[7.1].define(version: 2025_10_07_004035) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blood_pressure_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "systolic_pressure"
    t.integer "diastolic_pressure"
    t.integer "pulse_rate"
    t.datetime "measured_at"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_blood_pressure_records_on_user_id"
  end

  create_table "hospitals", force: :cascade do |t|
    t.string "name"
    t.text "address"
    t.string "phone_number"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_staff_assignments", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "staff_id", null: false
    t.bigint "hospital_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hospital_id"], name: "index_patient_staff_assignments_on_hospital_id"
    t.index ["patient_id", "staff_id", "hospital_id"], name: "index_patient_staff_assignments_unique", unique: true
    t.index ["patient_id"], name: "index_patient_staff_assignments_on_patient_id"
    t.index ["staff_id"], name: "index_patient_staff_assignments_on_staff_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_medical_staff", default: false, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "user_hospital_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "hospital_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "permission_level", default: 0, null: false
    t.index ["hospital_id"], name: "index_user_hospital_roles_on_hospital_id"
    t.index ["permission_level"], name: "index_user_hospital_roles_on_permission_level"
    t.index ["role_id"], name: "index_user_hospital_roles_on_role_id"
    t.index ["user_id", "hospital_id", "role_id"], name: "index_user_hospital_roles_unique", unique: true
    t.index ["user_id"], name: "index_user_hospital_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "user_id"
    t.bigint "current_role_id", null: false
    t.index ["current_role_id"], name: "index_users_on_current_role_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_id"], name: "index_users_on_user_id", unique: true
  end

  add_foreign_key "blood_pressure_records", "users"
  add_foreign_key "patient_staff_assignments", "hospitals"
  add_foreign_key "patient_staff_assignments", "users", column: "patient_id"
  add_foreign_key "patient_staff_assignments", "users", column: "staff_id"
  add_foreign_key "user_hospital_roles", "hospitals"
  add_foreign_key "user_hospital_roles", "roles"
  add_foreign_key "user_hospital_roles", "users"
  add_foreign_key "users", "roles", column: "current_role_id"
end
