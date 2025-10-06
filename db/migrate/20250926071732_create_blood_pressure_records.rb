class CreateBloodPressureRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :blood_pressure_records do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :systolic_pressure
      t.integer :diastolic_pressure
      t.integer :pulse_rate
      t.datetime :measured_at
      t.text :memo

      t.timestamps
    end
  end
end
