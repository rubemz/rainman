# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rainman/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Mazzi"]
  gem.email         = ["jmazzi@gmail.com"]
  gem.description   = %q{A library for writing drivers using the abstract factory pattern}
  gem.summary       = %q{Rainman is an experiment in writing drivers and handlers. It is a Ruby implementation of the abstract factory pattern. Abstract factories provide the general API used to interact with any number of interfaces. Interfaces perform actual operations. Rainman provides a simple DSL for implementing this design.}
  gem.homepage      = "http://www.eng5.com"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "rainman"
  gem.require_paths = ["lib"]
  gem.version       = Rainman::VERSION

  gem.add_development_dependency 'rspec', '~> 2.8.0'
  gem.add_development_dependency 'autotest-standalone', '~> 4.5.8'
  gem.add_development_dependency 'rake', '~> 0.9.2.2'
end
