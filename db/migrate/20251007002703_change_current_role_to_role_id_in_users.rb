class ChangeCurrentRoleToRoleIdInUsers < ActiveRecord::Migration[7.1]
  def up
    # current_roleカラムを削除
    remove_column :users, :current_role
    
    # current_role_idカラムを追加
    add_reference :users, :current_role, foreign_key: { to_table: :roles }, index: true
  end
  
  def down
    remove_reference :users, :current_role
    add_column :users, :current_role, :string, default: 'patient'
    add_index :users, :current_role
  end
end