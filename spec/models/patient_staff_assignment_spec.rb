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
require 'rails_helper'

RSpec.describe PatientStaffAssignment, type: :model do
  describe 'validations' do
    let(:hospital) { create(:hospital) }
    let(:patient) { create(:user, :patient) }
    let(:staff) { create(:user, :medical_staff) }

    it 'is valid with valid attributes' do
      assignment = build(:patient_staff_assignment, patient: patient, staff: staff, hospital: hospital)
      expect(assignment).to be_valid
    end

    describe 'patient_id uniqueness' do
      let!(:existing_assignment) { create(:patient_staff_assignment, patient: patient, staff: staff, hospital: hospital) }

      it 'is invalid with duplicate patient_id, staff_id, hospital_id combination' do
        duplicate_assignment = build(:patient_staff_assignment, patient: patient, staff: staff, hospital: hospital)
        expect(duplicate_assignment).not_to be_valid
        expect(duplicate_assignment.errors[:patient_id]).to include('は既にこの担当者に割り当てられています')
      end

      it 'is valid with same patient_id but different staff_id' do
        different_staff = create(:user, :medical_staff)
        valid_assignment = build(:patient_staff_assignment, patient: patient, staff: different_staff, hospital: hospital)
        expect(valid_assignment).to be_valid
      end

      it 'is valid with same patient_id and staff_id but different hospital_id' do
        different_hospital = create(:hospital)
        valid_assignment = build(:patient_staff_assignment, patient: patient, staff: staff, hospital: different_hospital)
        expect(valid_assignment).to be_valid
      end
    end

    describe 'custom validations' do
      describe '#patient_must_be_patient' do
        it 'is invalid when patient is not a patient' do
          non_patient = create(:user, :medical_staff) # 医療従事者は患者ではない
          assignment = build(:patient_staff_assignment, patient: non_patient, staff: staff, hospital: hospital)
          expect(assignment).not_to be_valid
          expect(assignment.errors[:patient]).to include('は患者である必要があります')
        end

        it 'is valid when patient is actually a patient' do
          assignment = build(:patient_staff_assignment, patient: patient, staff: staff, hospital: hospital)
          expect(assignment).to be_valid
        end
      end

      describe '#staff_must_be_medical_staff' do
        it 'is invalid when staff is not medical staff' do
          non_staff = create(:user, :patient) # 患者は医療従事者ではない
          assignment = build(:patient_staff_assignment, patient: patient, staff: non_staff, hospital: hospital)
          expect(assignment).not_to be_valid
          expect(assignment.errors[:staff]).to include('は医療従事者である必要があります')
        end

        it 'is valid when staff is actually medical staff' do
          assignment = build(:patient_staff_assignment, patient: patient, staff: staff, hospital: hospital)
          expect(assignment).to be_valid
        end
      end
    end
  end

  describe 'associations' do
    it 'belongs to patient' do
      association = described_class.reflect_on_association(:patient)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'User'
    end

    it 'belongs to staff' do
      association = described_class.reflect_on_association(:staff)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'User'
    end

    it 'belongs to hospital' do
      association = described_class.reflect_on_association(:hospital)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'factory' do
    it 'creates a valid patient staff assignment' do
      assignment = create(:patient_staff_assignment)
      expect(assignment).to be_valid
      expect(assignment.patient).to be_present
      expect(assignment.staff).to be_present
      expect(assignment.hospital).to be_present
    end

    it 'creates assignment with correct role types' do
      assignment = create(:patient_staff_assignment)
      expect(assignment.patient.patient?).to be true
      expect(assignment.staff.medical_staff?).to be true
    end
  end
end
