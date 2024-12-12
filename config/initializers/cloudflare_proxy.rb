require "net/http"

if Settings.cloudflare_proxy
  def fetch_with_timeout(url, timeout: 15)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request).body
    end
  rescue => e
    Rails.logger.warn "Failed to fetch #{url}: #{e.message}"
    ""
  end

  Rails.logger.info "Fetching latest Cloudflare IPs..."

  cf_ipv4_url = "https://www.cloudflare.com/ips-v4"
  cf_ipv6_url = "https://www.cloudflare.com/ips-v6"

  begin
    # Fetch Cloudflare IP ranges with timeout
    ipv4 = fetch_with_timeout(cf_ipv4_url).split("\n")
    ipv6 = fetch_with_timeout(cf_ipv6_url).split("\n")
    cloudflare_ips = ipv4 + ipv6
  rescue => e
    Rails.logger.warn "Failed to fetch Cloudflare IPs: #{e.message}"
    cloudflare_ips = [] # Fallback to no Cloudflare IPs
  end

  # Add Cloudflare IPs to existing trusted proxies
  Rails.application.config.action_dispatch.trusted_proxies ||= []
  Rails.application.config.action_dispatch.trusted_proxies += cloudflare_ips.filter_map do |ip|
    IPAddr.new(ip)
  rescue ArgumentError => e
    Rails.logger.warn "Invalid IP format skipped: #{ip} (#{e.message})"
    nil
  end

  Rails.logger.info "Cloudflare IPs added to trusted proxies."
end
