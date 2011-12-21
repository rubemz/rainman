# Rainman [![Rainman Build Status][Build Icon]][Build Status]

Rainman is an experiment in writing drivers and handlers.

[Build Icon]: https://secure.travis-ci.org/site5/rainman.png?branch=master
[Build Status]: http://travis-ci.org/site5/rainman

## Getting Started

```ruby
require 'rainman'

# Default is :autoload. You can also use :require or :none
Rainman.load_strategy :autoload

module Domain
  extend Rainman::Driver

  register_handler :opensrs do |config|
    config.username 'username'
    config.password 'pass'
    config.url      'https://www.opensrs.com/api'
  end

  register_handler :enom do |config|
    config.username 'weeee'
    config.password 'something'
    config.url      'https://reseller.enom.com'
  end

  add_option_all :domain => { :required => true }

  define_action :register do
    add_option :years  => { :default => 1 }
  end

  define_action :extend do
    add_option :years  => { :default => 1 }
  end

  define_action :something do
    remove_option :domain
  end

  define_action :other do
    add_option :domain => { :required => false }
  end

  define_action :whois

  namespace :nameservers do
    define_action :contacts
  end

  namespace :transfers, :inherit => true do
    # Top level options from add_option_all are inherited
    define_action :process
  end
end

# Implimenting a handler

module Domain
  class Enom
    include Rainman::Handler

    def register(opts = {})
    end
  end
end


# Using the driver and handler
class MyClass
  # Actions are mixed in
  include Domain::with_options(:default_handler => :enom)
end

my_class = Myclass.new

# Using :default_handler of :enom
my_class.register(:domain => 'test.com')
my_class.nameservers.contacts

# Using the :opensrs handler
my_class.with_handler :opensrs do |driver|
  driver.register(:domain => 'test.com')
end

class MyClass
  include Domain
end

# Using :default_handler of :opensrs
my_class.domain.register(:domain => 'test.com')
my_class.domain.nameservers.contacts

# Using the :opensrs handler
my_class.domain.with_handler :enom do |driver|
  driver.register(:domain => 'test.com')
end

```

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version
  unintentionally.
* Commit, do not bump version. (If you want to have your own version, that is
  fine but bump version in a commit by itself I can ignore when I pull).
* Send me a pull request. Bonus points for topic branches.

## Contributors

* [Justin Mazzi](https://github.com/jmazzi)
* [Joshua Priddle](https://github.com/itspriddle)

## Copyright

Copyright (c) 2011 Site5 LLC. See LICENSE for details.
