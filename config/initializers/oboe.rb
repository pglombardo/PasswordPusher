# AppNeta TraceView Initializer (the oboe gem)
# http://www.appneta.com/products/traceview/
#
# Details on configuring your sample rate:
# http://support.tv.appneta.com/support/solutions/articles/86336
#
# More information on instrumenting Ruby applications can be found here:
# http://support.tv.appneta.com/support/solutions/articles/86393

if defined?(Oboe::Config) 
  # Tracing Mode determines when traces should be initiated for incoming requests.  Valid
  # options are always, through (when using an instrumented Apache or Nginx) and never.
  #
  # If you're not using an instrumented Apache or Nginx, set this directive to always in
  # order to initiate tracing from Ruby.
  Oboe::Config[:tracing_mode] = 'through'
  
  # sample_rate is a value from 0 - 1m indicating the fraction of requests per million to trace
  # Oboe::Config[:sample_rate] = 300000
  
  # Verbose output of instrumentation initialization
  # Oboe::Config[:verbose] = false

  #
  # Resque Options
  #
  # :link_workers - associates Resque enqueue operations with the jobs they queue by piggybacking
  #                 an additional argument on the Redis queue that is stripped prior to job 
  #                 processing 
  #                 !!! Note: Make sure both the enqueue side and the Resque workers are instrumented
  #                 before enabling this or jobs will fail !!!
  #                 (Default: false)
  # Oboe::Config[:resque][:link_workers] = false
  #
  # Set to true to disable Resque argument logging (Default: false)
  # Oboe::Config[:resque][:log_args] = false
 
  # The oboe Ruby client has the ability to sanitize query literals
  # from SQL statements.  By default this is disabled.  Enable to
  # avoid collecting and reporting query literals to TraceView.
  Oboe::Config[:sanitize_sql] = true

  #
  # Enabling/Disabling Instrumentation
  #
  # If you're having trouble with one of the instrumentation libraries, they
  # can be individually disabled here by setting the :enabled
  # value to false:
  #
  # Oboe::Config[:action_controller][:enabled] = true
  # Oboe::Config[:active_record][:enabled] = true
  # Oboe::Config[:action_view][:enabled] = true
  # Oboe::Config[:cassandra][:enabled] = true
  # Oboe::Config[:dalli][:enabled] = true
  # Oboe::Config[:memcache][:enabled] = true
  # Oboe::Config[:memcached][:enabled] = true
  # Oboe::Config[:mongo][:enabled] = true
  # Oboe::Config[:moped][:enabled] = true
  # Oboe::Config[:nethttp][:enabled] = true
  # Oboe::Config[:resque][:enabled] = true
  
  #
  # Enabling/Disabling Backtrace Collection
  #
  # Instrumentation can optionally collect backtraces as they collect
  # performance metrics.  Note that this has a negative impact on
  # performance but can be useful when trying to locate the source of
  # a certain call or operation.  
  #
  Oboe::Config[:action_controller][:collect_backtraces] = false
  Oboe::Config[:active_record][:collect_backtraces] = false
  Oboe::Config[:action_view][:collect_backtraces] = false
  Oboe::Config[:cassandra][:collect_backtraces] = false
  Oboe::Config[:dalli][:collect_backtraces] = false
  Oboe::Config[:memcache][:collect_backtraces] = false
  Oboe::Config[:memcached][:collect_backtraces] = false
  Oboe::Config[:mongo][:collect_backtraces] = false
  Oboe::Config[:moped][:collect_backtraces] = false
  Oboe::Config[:nethttp][:collect_backtraces] = false
  Oboe::Config[:resque][:collect_backtraces] = false
  #
end
