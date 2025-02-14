module Pwpush
  module TokenAuthentication
    extend ActiveSupport::Concern

    ## regenerate_authentication_token
    #
    # Regenerate the authentication token
    #
    # This method regenerates the authentication token for the user.
    # It generates a new token and saves it to the user record.
    #
    def regenerate_authentication_token!
      self.authentication_token = generate_authentication_token
      save!
    end

    ## purge_authentication_token!
    #
    # Purge the authentication token
    #
    # This method purges the authentication token for the user.
    # It sets the authentication token to nil and saves the user record.
    #
    def purge_authentication_token!
      self.authentication_token = nil
      save!
    end

    private

    ## generate_authentication_token
    #
    # Generate an authentication token
    #
    # This method generates a unique authentication token for the user.
    # It generates a random token and checks if it already exists in the database.
    # If the token already exists, it generates a new token until it finds a unique one.
    #
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.exists?(authentication_token: token)
      end
    end
  end
end
