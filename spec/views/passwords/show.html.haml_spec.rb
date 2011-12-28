require 'spec_helper'

describe "passwords/show.html.haml" do
  before(:each) do
    @password = assign(:password, stub_model(Password))
  end

  it "renders attributes in <p>" do
    render
  end
end
