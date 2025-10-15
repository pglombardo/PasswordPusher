# MissionControl::Jobs configuration
if defined?(MissionControl::Jobs)
  # Ensure Solid Queue is properly integrated
  if defined?(SolidQueue)
    # Solid Queue is available and should work with MissionControl::Jobs
    Rails.logger.info "MissionControl::Jobs configured with Solid Queue"
  end
end
