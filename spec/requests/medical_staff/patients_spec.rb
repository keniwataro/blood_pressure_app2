require 'rails_helper'

RSpec.describe "MedicalStaff::Patients", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/medical_staff/patients/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/medical_staff/patients/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/medical_staff/patients/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/medical_staff/patients/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/medical_staff/patients/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/medical_staff/patients/update"
      expect(response).to have_http_status(:success)
    end
  end

end
