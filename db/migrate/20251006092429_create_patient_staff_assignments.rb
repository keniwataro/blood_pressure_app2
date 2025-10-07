class CreatePatientStaffAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :patient_staff_assignments do |t|
      t.references :patient, null: false, foreign_key: { to_table: :users }
      t.references :staff, null: false, foreign_key: { to_table: :users }
      t.references :hospital, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :patient_staff_assignments, [:patient_id, :staff_id, :hospital_id], 
              unique: true, 
              name: 'index_patient_staff_assignments_unique'
  end
end
