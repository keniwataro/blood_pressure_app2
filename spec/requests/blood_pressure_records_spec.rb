require 'rails_helper'

RSpec.describe "BloodPressureRecords", type: :request do
  let(:patient) { create(:user, :patient) }
  let(:blood_pressure_record) { create(:blood_pressure_record, user: patient) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /blood_pressure_records" do
    it "returns http success for patient" do
      authenticate_request(patient)
      get blood_pressure_records_path, headers: default_headers
      expect_success_response
    end
  end

  describe "GET /blood_pressure_records/:id" do
    it "returns http success for record owner" do
      authenticate_request(patient)
      get blood_pressure_record_path(blood_pressure_record), headers: default_headers
      expect_success_response
    end
  end

  describe "GET /blood_pressure_records/new" do
    it "returns http success for patient" do
      authenticate_request(patient)
      get new_blood_pressure_record_path, headers: default_headers
      expect_success_response
    end
  end

  describe "GET /blood_pressure_records/:id/edit" do
    it "returns http success for record owner" do
      authenticate_request(patient)
      get edit_blood_pressure_record_path(blood_pressure_record), headers: default_headers
      expect_success_response
    end
  end

  describe "POST /blood_pressure_records" do
    let(:valid_attributes) {
      { blood_pressure_record: attributes_for(:blood_pressure_record) }
    }

    it "creates a new blood pressure record" do
      authenticate_request(patient)
      expect {
        post blood_pressure_records_path, params: valid_attributes, headers: default_headers
      }.to change(BloodPressureRecord, :count).by(1)
      expect_created_response
    end
  end

  describe "PATCH /blood_pressure_records/:id" do
    let(:new_attributes) {
      { blood_pressure_record: { systolic_pressure: 140 } }
    }

    it "updates the requested blood pressure record" do
      authenticate_request(patient)
      patch blood_pressure_record_path(blood_pressure_record), params: new_attributes, headers: default_headers
      blood_pressure_record.reload
      expect(blood_pressure_record.systolic_pressure).to eq(140)
      expect_redirect_response
    end
  end

  describe "DELETE /blood_pressure_records/:id" do
    let!(:record_to_delete) { create(:blood_pressure_record, user: patient) }

    it "destroys the requested blood pressure record" do
      authenticate_request(patient)
      expect {
        delete blood_pressure_record_path(record_to_delete), headers: default_headers
      }.to change(BloodPressureRecord, :count).by(-1)
      expect_redirect_response
    end
  end
end
