# frozen_string_literal: true

if defined?(Rack::Timeout::StateChangeLoggingObserver::STATE_LOG_LEVEL)
  Rack::Timeout::StateChangeLoggingObserver::STATE_LOG_LEVEL[:ready] = :debug
  Rack::Timeout::StateChangeLoggingObserver::STATE_LOG_LEVEL[:completed] = :debug
end
