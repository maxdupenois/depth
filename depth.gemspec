# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'depth/version'

Gem::Specification.new do |spec|
  spec.name          = "Complex Hash"
  spec.version       = Depth::VERSION
  spec.authors       = ["Max"]
  spec.email         = ["max.dupenois@gmail.com"]
  spec.summary       = %q{Depth is a utility gem for dealing with nested hashes and arrays}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/maxdupenois/depth"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov"
end