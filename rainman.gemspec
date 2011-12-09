# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rainman/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Mazzi"]
  gem.email         = ["jmazzi@gmail.com"]
  gem.description   = %q{A library for abstracting drivers}
  gem.summary       = %q{A library for abstracting drivers}
  gem.homepage      = "http://www.eng5.com"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "rainman"
  gem.require_paths = ["lib"]
  gem.version       = Rainman::VERSION

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'autotest-standalone'
  gem.add_dependency 'activesupport', '~>3.1.3'
  gem.add_dependency 'i18n', '~>0.6.0'
end
