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
            if controller_path == "users/first_runs"
              boot_code = FirstRunBootCode.code
              puts <<~MESSAGE
                =======================================================================================
                FIRST RUN SETUP REQUIRED
                =======================================================================================
                No users detected. To complete first-run setup, you will need the following boot code:

                  Boot Code: #{boot_code}

                This code is required to create the first administrator account.
                The code will expire once the first user is created. It may also be cleared when
                the container is restarted, depending on how temporary storage is configured.
                =======================================================================================
              MESSAGE
            end
          end
          # Use controller_path, not request.path vs first_run_path: SetLocale default_url_options
          # (e.g. ?locale=en) can change generated paths and break start_with?, causing a redirect loop.
          return if controller_path == "users/first_runs"

          redirect_to first_run_url
        end
      end
    end
  end
end
