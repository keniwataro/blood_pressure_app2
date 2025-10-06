require 'rails_helper'

RSpec.describe "BloodPressureRecords", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/blood_pressure_records/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/blood_pressure_records/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/blood_pressure_records/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/blood_pressure_records/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/blood_pressure_records/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/blood_pressure_records/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/blood_pressure_records/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
