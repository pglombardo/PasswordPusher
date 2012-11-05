if defined?(Oboe) and (Rails.env == 'production' or Rails.env == 'staging')
  #Oboe::Config[:tracing_mode] = 'through'
  #Oboe::Config[:sample_rate] = 1000000
  Oboe::Config[:verbose] = true
end

