# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rainman/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Mazzi"]
  gem.email         = ["jmazzi@gmail.com"]
  gem.description   = %q{A library for abstracting drivers}
  gem.summary       = %q{A library for abstracting drivers}
  gem.homepage      = "http://www.eng5.com"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "rainman"
  gem.require_paths = ["lib"]
  gem.version       = Rainman::VERSION

  gem.add_development_dependency 'rspec', '~> 2.7.0'
  gem.add_development_dependency 'autotest-standalone', '~> 4.5.8'
  gem.add_development_dependency 'rake', '~> 0.9.2.2'
end
