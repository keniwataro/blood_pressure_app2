require 'rails_helper'

RSpec.describe "MedicalStaff::BloodPressureRecords", type: :request do
  let(:hospital) { create(:hospital) }
  let(:medical_staff) { create(:user, :medical_staff) }
  let(:patient) { create(:user, :patient) }
  let(:blood_pressure_record) { create(:blood_pressure_record, user: patient) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  before do
    # 医療従事者と患者を同じ病院に所属させる
    # 既存のUserHospitalRoleを更新
    if medical_staff.user_hospital_roles.any?
      medical_staff.user_hospital_roles.first.update(hospital: hospital)
    end
    if patient.user_hospital_roles.any?
      patient.user_hospital_roles.first.update(hospital: hospital)
    end
  end

  describe "GET /medical_staff/patients/:patient_id/blood_pressure_records/:id" do
    it "returns http success for medical staff" do
      authenticate_request(medical_staff)
      get medical_staff_patient_blood_pressure_record_path(patient, blood_pressure_record), headers: default_headers
      expect_success_response
    end
  end
end
