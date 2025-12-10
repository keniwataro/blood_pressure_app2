require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:patient) { create(:user, :patient) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /dashboard" do
    it "redirects to blood pressure records for authenticated patient" do
      authenticate_request(patient)
      get authenticated_root_path, headers: default_headers
      expect_redirect_response
    end
  end
end
