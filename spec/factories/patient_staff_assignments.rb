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
FactoryBot.define do
  factory :patient_staff_assignment do
    patient { nil }
    staff { nil }
    hospital { nil }
  end
end
