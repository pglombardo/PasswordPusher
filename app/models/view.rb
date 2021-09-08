class View < ApplicationRecord
  belongs_to :password
  belongs_to :user
  #attr_accessible :password_id, :ip, :user_agent
end
