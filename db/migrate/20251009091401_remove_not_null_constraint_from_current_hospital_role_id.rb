class RemoveNotNullConstraintFromCurrentHospitalRoleId < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :current_hospital_role_id, true
  end
end
