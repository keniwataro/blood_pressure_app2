# == Schema Information
#
# Table name: patient_staff_assignments
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  hospital_id :bigint           not null
#  patient_id  :bigint           not null
#  staff_id    :bigint           not null
#
# Indexes
#
#  index_patient_staff_assignments_on_hospital_id  (hospital_id)
#  index_patient_staff_assignments_on_patient_id   (patient_id)
#  index_patient_staff_assignments_on_staff_id     (staff_id)
#  index_patient_staff_assignments_unique          (patient_id,staff_id,hospital_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (hospital_id => hospitals.id)
#  fk_rails_...  (patient_id => users.id)
#  fk_rails_...  (staff_id => users.id)
#
class PatientStaffAssignment < ApplicationRecord
  belongs_to :patient, class_name: 'User'
  belongs_to :staff, class_name: 'User'
  belongs_to :hospital
  
  validates :patient_id, uniqueness: { scope: [:staff_id, :hospital_id], 
                                       message: "は既にこの担当者に割り当てられています" }
  
  # 患者が実際に患者であることを確認
  validate :patient_must_be_patient
  # スタッフが実際に医療従事者であることを確認
  validate :staff_must_be_medical_staff
  
  private
  
  def patient_must_be_patient
    unless patient&.patient?
      errors.add(:patient, "は患者である必要があります")
    end
  end
  
  def staff_must_be_medical_staff
    unless staff&.medical_staff?
      errors.add(:staff, "は医療従事者である必要があります")
    end
  end
end
