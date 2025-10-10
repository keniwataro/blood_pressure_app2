class RenameCurrentRoleIdToCurrentHospitalRoleId < ActiveRecord::Migration[7.1]
  def up
    rename_column :users, :current_role_id, :current_hospital_role_id
    # インデックスは自動的にリネームされる

    # 外部キー制約を変更
    remove_foreign_key :users, :roles, column: :current_hospital_role_id
    add_foreign_key :users, :user_hospital_roles, column: :current_hospital_role_id
  end

  def down
    remove_foreign_key :users, :user_hospital_roles, column: :current_hospital_role_id
    add_foreign_key :users, :roles, column: :current_hospital_role_id
    rename_column :users, :current_hospital_role_id, :current_role_id
  end
end
