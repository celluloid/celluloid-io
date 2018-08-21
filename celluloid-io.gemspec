# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "celluloid/io/version"

Gem::Specification.new do |gem|
  gem.name          = "celluloid-io"
  gem.version       = Celluloid::IO::VERSION
  gem.license       = "MIT"
  gem.authors       = ["Tony Arcieri", "Donovan Keme"]
  gem.email         = ["tony.arcieri@gmail.com", "code@extremist.digital"]
  gem.description   = "Evented IO for Celluloid actors"
  gem.summary       = "Celluloid::IO allows you to monitor multiple IO objects within a Celluloid actor"
  gem.homepage      = "http://github.com/celluloid/celluloid-io"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.add_dependency "nio4r", ">= 1.1"

  gem.add_development_dependency "rb-fsevent", "~> 0.9.1" if RUBY_PLATFORM =~ /darwin/
end
