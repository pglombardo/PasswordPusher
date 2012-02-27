require 'spec_helper'

describe ApiController do

  describe "GET 'create'" do
    it "returns http success" do
      get 'create'
      response.should be_success
    end
  end

  describe "GET 'generate'" do
    it "returns http success" do
      get 'generate'
      response.should be_success
    end
  end

  describe "GET 'list'" do
    it "returns http success" do
      get 'list'
      response.should be_success
    end
  end

  describe "GET 'config'" do
    it "returns http success" do
      get 'config'
      response.should be_success
    end
  end

end
