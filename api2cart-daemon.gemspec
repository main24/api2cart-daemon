# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'api2cart/daemon/version'

Gem::Specification.new do |spec|
  spec.name          = "api2cart-daemon"
  spec.version       = Api2cart::Daemon::VERSION
  spec.authors       = ["Daniel Vartanov"]
  spec.email         = ["dan@vartanov.net"]
  spec.summary       = %q{Anti throttling proxy server for API2Cart requests}
  spec.description   = %q{Anti throttling proxy server for API2Cart requests}
  spec.homepage      = "https://github.com/DanielVartanov/api2cart-daemon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'celluloid-io'
  spec.add_dependency 'http_parser.rb'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "http"
end
