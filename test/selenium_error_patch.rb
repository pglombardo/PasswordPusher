# Taken from https://github.com/alphagov/forms-admin/commit/5ea98767d765a396ed06cf2cba8f9afb1b10fc0e#diff-c36c07a0c7f499b1b95634f9dce1a10ebf4d10a9dee872f39f746a9efa555ddbR1-R34
# Monkey patch for a specific intermittent Selenium error.
#
# Intermittently, Selenium/Chromedriver raises `Selenium::WebDriver::Error::UnknownError`
# with the message "Node with given id does not belong to the document".

# Capybara's automatic waiting/retrying mechanism doesn't catch it,
# leading to failure.
#
# We intercept the initialization of `UnknownError`. If the message matches this specific
# case, we raise a `StaleElementReferenceError` instead. This uses Capybara's
# retry logic which makes doesn't fail the test
#
# This can be removed once the following issue is resolved:
# https://github.com/teamcapybara/capybara/issues/2800
#
# taken from the following issue:
# https://github.com/teamcapybara/capybara/issues/2800#issuecomment-3049956982

# rubocop:disable Style/Alias, Style/IfUnlessModifier, Style/StringLiterals
module Selenium
  module WebDriver
    module Error
      class UnknownError
        alias_method :old_initialize, :initialize
        def initialize(msg = nil)
          if msg&.include?("Node with given id does not belong to the document")
            raise StaleElementReferenceError, msg
          end

          old_initialize(msg)
        end
      end
    end
  end
end
# rubocop:enable Style/Alias, Style/IfUnlessModifier, Style/StringLiterals
