# frozen_string_literal: true

class Rack::Attack
  blocklist("no instana clicks") do |request|
    candidates = [/instana.io/]
    candidates.find { |c| request.referer =~ c }
  end
end
