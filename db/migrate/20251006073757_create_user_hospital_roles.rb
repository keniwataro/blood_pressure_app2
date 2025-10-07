class CreateUserHospitalRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_hospital_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :hospital, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    
    # 同じユーザーが同じ病院で同じ役割を重複して持たないようにする
    add_index :user_hospital_roles, [:user_id, :hospital_id, :role_id], unique: true, name: 'index_user_hospital_roles_unique'
  end
end
