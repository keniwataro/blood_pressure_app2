class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.boolean :is_medical_staff, default: false, null: false
      t.string :description

      t.timestamps
    end
    
    add_index :roles, :name, unique: true
  end
end
