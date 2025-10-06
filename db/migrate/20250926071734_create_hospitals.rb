class CreateHospitals < ActiveRecord::Migration[7.1]
  def change
    create_table :hospitals do |t|
      t.string :name
      t.text :address
      t.string :phone_number
      t.string :website

      t.timestamps
    end
  end
end
