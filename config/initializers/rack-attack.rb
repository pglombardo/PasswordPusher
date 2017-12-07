class Rack::Attack
  blocklist("no instana clicks") do |request|
    spammers = [/instana.io/]
    spammers.find { |spammer| request.referer =~ spammer }
  end
end
