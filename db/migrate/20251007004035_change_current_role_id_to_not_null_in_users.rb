class ChangeCurrentRoleIdToNotNullInUsers < ActiveRecord::Migration[7.1]
  def up
    # 既存のユーザーでcurrent_role_idがnilの場合、患者の役割を設定
    patient_role = Role.find_by(name: '患者')
    if patient_role
      User.where(current_role_id: nil).update_all(current_role_id: patient_role.id)
    end
    
    # current_role_idをNOT NULLに変更
    change_column_null :users, :current_role_id, false
  end
  
  def down
    change_column_null :users, :current_role_id, true
  end
end