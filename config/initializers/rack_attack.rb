if defined? Rack::Attack
  class Rack::Attack
    # rack-attack helps you protect your Rails application from bad clients.
    # You can use it to allow, block, and throttle requests.
    # See https://github.com/rack/rack-attack for more details

    # By default, rack-attack is enabled for all environments
    # Rack::Attack.enabled = Rails.env.production?

    ### Cache

    # rack-attack uses the Rails.cache for storing throttling, allow2ban, and fail2ban filtering.
    # They recommend using a separate Redis database to prevent an attack from taking down your main Redis database

    # Use the memory store for faster tests
    if Rails.env.test?
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      # else
      #   Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: "...")
    end

    # Return a Retry-After header for throttled requests
    Rack::Attack.throttled_response_retry_after_header = true

    ### Throttle Spammy Clients

    # If any single client IP is making tons of requests, then they're
    # probably malicious or a poorly-configured scraper. Either way, they
    # don't deserve to hog all of the app server's CPU. Cut them off!

    unless Rails.env.test?
      # Throttle all requests by IP
      #
      throttle("req/ip", limit: Settings.throttling.minute, period: 1.minute) do |req|
        req.ip # unless req.path.start_with?('/assets')
      end

      # Throttle API requests by IP address
      #
      throttle("api/ip", limit: Settings.throttling.second, period: 1.second) do |req|
        if req.path == "/api"
          req.ip
        end
      end
    end

    ### Prevent Brute-Force Login Attacks

    # The most common brute-force login attack is a brute-force password
    # attack where an attacker simply tries a large number of emails and
    # passwords to see if any credentials match.
    #
    # Another common method of attack is to use a swarm of computers with
    # different IPs to try brute-forcing a password for a specific account.

    # Throttle POST requests to /users/sign_in by IP address
    #
    # throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    #   if req.path == "/users/sign_in" && req.post?
    #     req.ip
    #   end
    # end

    # Throttle POST requests to /users/sign_in by email param
    #
    # Note: This creates a problem where a malicious user could intentionally
    # throttle logins for another user and force their login requests to be
    # denied, but that's not very common and shouldn't happen to you. (Knock
    # on wood!)
    #
    # throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    #   if req.path == "/users/sign_in" && req.post?
    #     # Normalize the email, using the same logic as your authentication process, to
    #     # protect against rate limit bypasses. Return the normalized email if present, nil otherwise.
    #     req.params["email"].to_s.downcase.gsub(/\s+/, "").presence
    #   end
    # end
  end
end
