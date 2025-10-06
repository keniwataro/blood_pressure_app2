require 'rails_helper'

RSpec.describe "Charts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/charts/index"
      expect(response).to have_http_status(:success)
    end
  end

end
