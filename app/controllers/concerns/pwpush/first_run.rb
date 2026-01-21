# frozen_string_literal: true

module Pwpush
  module FirstRun
    extend ActiveSupport::Concern

    included do
      before_action :ensure_user_exists

      private

      def ensure_user_exists
        return if ENV.key?("PWP_PUBLIC_GATEWAY")

        if FirstRunBootCode.needed?
          unless Rails.env.test?
            puts <<~MESSAGE
              =======================================================================================
              FIRST RUN SETUP REQUIRED
              =======================================================================================
              No users detected. To complete first-run setup, you will need the following boot code:

                Boot Code: #{FirstRunBootCode.code}

              This code is required to create the first administrator account.
              The code will expire once the first user is created or the container is restarted.
              =======================================================================================
            MESSAGE
          end
          return if request.path.include?("first_run")

          redirect_to first_run_url
        end
      end
    end
  end
end
