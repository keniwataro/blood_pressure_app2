class AddCurrentRoleToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :current_role, :string, default: 'patient'
    add_index :users, :current_role
  end
end
