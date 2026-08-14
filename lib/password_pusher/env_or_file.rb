# frozen_string_literal: true

module PasswordPusher
  # Resolve a secret from an environment variable, or from a file path given by
  # a companion +NAME_FILE+ variable (Docker Compose/Swarm secrets convention).
  #
  # Resolution order:
  # 1. If +NAME+ is set and non-empty, use that value.
  # 2. Else if +NAME_FILE+ is set, read and strip that file (fail if unreadable).
  # 3. Else return +nil+ (caller applies its own default).
  module EnvOrFile
    class Error < StandardError; end

    module_function

    def read(name)
      value = ENV[name]
      return value if value && !value.empty?

      path = ENV["#{name}_FILE"]
      return nil if path.nil? || path.empty?

      unless File.readable?(path)
        raise Error, "#{name}_FILE is set but not readable: #{path}"
      end

      File.read(path).strip
    end
  end
end
