class View < ActiveRecord::Base
  belongs_to :password
  attr_accessible :password_id, :ip, :user_agent
end
