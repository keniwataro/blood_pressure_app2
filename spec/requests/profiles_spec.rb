require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:patient) { create(:user, :patient) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /profile" do
    it "returns http success for authenticated user" do
      authenticate_request(patient)
      get profile_path, headers: default_headers
      expect_success_response
    end

    it "redirects to login for unauthenticated user" do
      get profile_path, headers: default_headers
      expect_redirect_response
    end
  end

  describe "GET /profile/edit" do
    it "returns http success for authenticated user" do
      authenticate_request(patient)
      get edit_profile_path, headers: default_headers
      expect_success_response
    end
  end

  describe "PATCH /profile" do
    let(:new_attributes) {
      { user: { name: "Updated Name" } }
    }

    it "updates the profile" do
      authenticate_request(patient)
      patch profile_path, params: new_attributes, headers: default_headers
      patient.reload
      expect(patient.name).to eq("Updated Name")
      expect_redirect_response
    end
  end
end
