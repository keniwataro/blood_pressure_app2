require 'rails_helper'

RSpec.describe "MedicalStaff::BloodPressureRecords", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/medical_staff/blood_pressure_records/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/medical_staff/blood_pressure_records/show"
      expect(response).to have_http_status(:success)
    end
  end

end
