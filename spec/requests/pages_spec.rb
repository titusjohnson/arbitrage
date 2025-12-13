require 'rails_helper'

RSpec.describe "Pages", type: :request do
  # Ensure at least one location exists for game creation
  before(:each) do
    create(:location) unless Location.exists?
  end

  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
