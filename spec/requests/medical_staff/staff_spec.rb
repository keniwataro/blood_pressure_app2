require 'rails_helper'

RSpec.describe "MedicalStaff::Staffs", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/medical_staff/staff/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/medical_staff/staff/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/medical_staff/staff/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/medical_staff/staff/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/medical_staff/staff/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/medical_staff/staff/update"
      expect(response).to have_http_status(:success)
    end
  end

end
