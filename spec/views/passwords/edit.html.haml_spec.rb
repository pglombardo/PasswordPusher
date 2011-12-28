require 'spec_helper'

describe "passwords/edit.html.haml" do
  before(:each) do
    @password = assign(:password, stub_model(Password))
  end

  it "renders the edit password form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => passwords_path(@password), :method => "post" do
    end
  end
end
