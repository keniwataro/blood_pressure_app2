class AddUserIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :user_id, :string
    add_index :users, :user_id, unique: true
  end
end
