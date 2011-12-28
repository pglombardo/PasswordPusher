require 'spec_helper'

describe "passwords/index.html.haml" do
  before(:each) do
    assign(:passwords, [
      stub_model(Password),
      stub_model(Password)
    ])
  end

  it "renders a list of passwords" do
    render
  end
end
