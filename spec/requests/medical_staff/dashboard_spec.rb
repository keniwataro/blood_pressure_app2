require 'rails_helper'

RSpec.describe "MedicalStaff::Dashboards", type: :request do
  let(:medical_staff) { create(:user, :medical_staff) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /medical_staff" do
    it "returns http success for medical staff" do
      authenticate_request(medical_staff)
      get medical_staff_root_path, headers: default_headers
      expect_success_response
    end
  end
end
