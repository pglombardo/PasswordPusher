class UsersController < ApplicationController
  before_action :authenticate_user!

  def passwords
    @passwords = current_user.passwords.select {|p| !p.expired?}
  end
end
