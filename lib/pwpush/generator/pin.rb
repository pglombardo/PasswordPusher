# frozen_string_literal: true

module Pwpush
  module Generator
    class Pin
      def initialize(length:)
        @length = length
      end

      def generate
        Array.new(@length) { Charsets::PIN_DIGITS[SecureRandom.random_number(10)] }.join
      end

      def entropy_bits
        (@length * Math.log2(10)).round(1)
      end
    end
  end
end
