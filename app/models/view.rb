class View < ApplicationRecord
  belongs_to :password
  belongs_to :user, optional: true
end
