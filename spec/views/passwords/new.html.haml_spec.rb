require 'spec_helper'

describe "passwords/new.html.haml" do
  before(:each) do
    assign(:password, stub_model(Password).as_new_record)
  end

  it "renders new password form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => passwords_path, :method => "post" do
    end
  end
end
