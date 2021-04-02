# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# require 'pwpush/version'

Gem::Specification.new do |spec|
  spec.name          = "pwpush"
  spec.version       = '0.1.0'
  spec.authors       = ["Peter Giacomo Lombardo"]
  spec.email         = ["nosis@rbx.run"]

  spec.summary       = %q{Password Pusher is an application to securely communicate passwords over the web.}
  spec.description   = %q{Passwords automatically expire after a certain number of views and/or time has passed.}
  spec.homepage      = "https://pwpush.com"
  spec.license       = "GPLv3"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata['allowed_push_host'] = "https://rubygems.org"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler" ">= 2.0.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest"
end
