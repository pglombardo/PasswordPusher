require File.dirname(__FILE__) + '/../spec_helper'

describe View do
  it "should be valid" do
    View.new.should be_valid
  end
end
