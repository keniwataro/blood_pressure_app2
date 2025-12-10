require 'rails_helper'

RSpec.describe "Admin::Hospitals", type: :request do
  let(:system_admin) { create(:user, :system_admin) }
  let(:hospital) { create(:hospital) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /admin/hospitals" do
    it "returns http success for system admin" do
      authenticate_request(system_admin)
      get admin_hospitals_path, headers: default_headers
      expect_success_response
    end
  end

  describe "GET /admin/hospitals/:id" do
    it "returns http success for system admin" do
      authenticate_request(system_admin)
      get admin_hospital_path(hospital), headers: default_headers
      expect_success_response
    end
  end

  describe "GET /admin/hospitals/new" do
    it "returns http success for system admin" do
      authenticate_request(system_admin)
      get new_admin_hospital_path, headers: default_headers
      expect_success_response
    end
  end

  describe "GET /admin/hospitals/:id/edit" do
    it "returns http success for system admin" do
      authenticate_request(system_admin)
      get edit_admin_hospital_path(hospital), headers: default_headers
      expect_success_response
    end
  end

  describe "POST /admin/hospitals" do
    let(:valid_attributes) {
      { hospital: attributes_for(:hospital) }
    }

    it "creates a new hospital" do
      authenticate_request(system_admin)
      expect {
        post admin_hospitals_path, params: valid_attributes, headers: default_headers
      }.to change(Hospital, :count).by(1)
      expect_redirect_response
    end
  end

  describe "PATCH /admin/hospitals/:id" do
    let(:new_attributes) {
      { hospital: { name: "Updated Hospital" } }
    }

    it "updates the requested hospital" do
      authenticate_request(system_admin)
      patch admin_hospital_path(hospital), params: new_attributes, headers: default_headers
      hospital.reload
      expect(hospital.name).to eq("Updated Hospital")
      expect_redirect_response
    end
  end

  describe "DELETE /admin/hospitals/:id" do
    let!(:hospital_to_delete) { create(:hospital) }

    it "destroys the requested hospital" do
      authenticate_request(system_admin)
      expect {
        delete admin_hospital_path(hospital_to_delete), headers: default_headers
      }.to change(Hospital, :count).by(-1)
      expect_redirect_response
    end
  end
end
