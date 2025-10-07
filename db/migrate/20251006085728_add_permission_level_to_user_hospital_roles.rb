class AddPermissionLevelToUserHospitalRoles < ActiveRecord::Migration[7.1]
  def change
    add_column :user_hospital_roles, :permission_level, :integer, default: 0, null: false
    add_index :user_hospital_roles, :permission_level
  end
end
