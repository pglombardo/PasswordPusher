class Password < ActiveRecord::Base
  has_many :views, :dependent => :destroy
end
