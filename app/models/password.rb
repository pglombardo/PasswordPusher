class Password < ActiveRecord::Base
  attr_accessible :payload, :expire_after_days, :expire_after_views
  has_many :views, :dependent => :destroy
end
