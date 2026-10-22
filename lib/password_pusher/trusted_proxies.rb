# frozen_string_literal: true

require "ipaddr"

module PasswordPusher
  # Turn Settings.trusted_proxies into IPAddr objects.
  #
  # Rails trusts a proxy when `proxy === ip`. A String matches only by
  # equality, so a CIDR such as "203.0.113.0/24" never matches a host in that
  # range. IPAddr#=== does.
  module TrustedProxies
    module_function

    def parse(value)
      entries_for(value).filter_map { |entry| ip_addr_for(entry) }
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
