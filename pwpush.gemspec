# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# require 'pwpush/version'

Gem::Specification.new do |spec|
  spec.name = "pwpush"
  spec.version = "0.1.0"
  spec.authors = ["Peter Giacomo Lombardo"]
  spec.email = ["pglombardo@gmail.com"]

  spec.summary = "Password Pusher is an application to securely communicate passwords over the web."
  spec.description = "Passwords automatically expire after a certain number of views and/or time has passed."
  spec.homepage = "https://pwpush.com"
  spec.license = "Apache 2.0"

  spec.required_ruby_version = ">= 3.2"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #  spec.metadata['allowed_push_host'] = "https://rubygems.org"
  # else
  #  raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"
end
