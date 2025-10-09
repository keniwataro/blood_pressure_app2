class AddIsHospitalRoleToRoles < ActiveRecord::Migration[7.1]
  def change
    add_column :roles, :is_hospital_role, :boolean, default: true, null: false

    # 既存レコードの更新
    Role.reset_column_information
    Role.where(name: 'システム管理者').update_all(is_hospital_role: false)
    Role.where.not(name: 'システム管理者').update_all(is_hospital_role: true)
  end
end
