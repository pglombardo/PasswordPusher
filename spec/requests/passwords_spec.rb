require 'spec_helper'

describe "Passwords" do
  describe "GET /passwords" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get passwords_path
      response.status.should be(200)
    end
  end
end
