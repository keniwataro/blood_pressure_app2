require 'rails_helper'

RSpec.describe "MedicalStaff::Dashboards", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/medical_staff/dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end

end
