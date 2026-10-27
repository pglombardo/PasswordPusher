# frozen_string_literal: true

require "ipaddr"

module PasswordPusher
  # Trusted proxy configuration shared by ActionDispatch and header gating.
  module TrustedProxies
    module_function

    # Rails trusts a proxy with `proxy === ip`. Use IPAddr for every range:
    # unanchored regular expressions can classify public addresses incorrectly.
    DEFAULTS = %w[
      127.0.0.0/8
      ::1
      10.0.0.0/8
      172.16.0.0/12
      192.168.0.0/16
      169.254.0.0/16
      100.64.0.0/10
      fc00::/7
      fe80::/10
    ].map { |range| IPAddr.new(range) }.freeze

    # Turn Settings.trusted_proxies into IPAddr objects.
    def parse(value)
      entries_for(value).filter_map { |entry| ip_addr_for(entry) }
    end

    def trusted?(ip, proxies = DEFAULTS)
      # Dual-stack listeners report an IPv4 peer as ::ffff:10.0.0.5. IPAddr
      # does not match that form against an IPv4 range until it is native.
      address = IPAddr.new(ip).native
      proxies.any? { |proxy| proxy === address }
    rescue IPAddr::Error
      false
    end

    def entries_for(value)
      items = value.is_a?(Array) ? value : [value]
      items.flat_map { |item| item.to_s.split(",") }.map(&:strip).reject(&:empty?)
    end

    def ip_addr_for(entry)
      IPAddr.new(entry)
    rescue ArgumentError => e
      Rails.logger&.warn("Invalid trusted proxy skipped: #{entry} (#{e.message})")
      nil
    end
  end
end
