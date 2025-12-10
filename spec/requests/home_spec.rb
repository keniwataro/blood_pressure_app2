require 'rails_helper'

RSpec.describe "Homes", type: :request do
  let(:patient) { create(:user, :patient) }
  let(:default_headers) { { 'HOST' => 'localhost' } }

  describe "GET /home/index" do
    it "returns http success for authenticated user" do
      authenticate_request(patient)
      get home_index_path, headers: default_headers
      expect_success_response
    end
  end
end
