# Rainman [![Rainman Build Status][Build Icon]][Build Status]

Rainman is an experiment in writing drivers and handlers. It is a Ruby
implementation of the [abstract factory pattern][1]. Abstract factories provide
the general API used to interact with any number of interfaces. Interfaces
perform actual operations. Rainman provides a simple DSL for implementing this
design.

[1]: http://en.wikipedia.org/wiki/Abstract_factory_pattern

[Build Icon]: https://secure.travis-ci.org/site5/rainman.png?branch=master
[Build Status]: http://travis-ci.org/site5/rainman

## Drivers & Handlers

In Rainman, drivers represent abstract factories and handlers represent the
interfaces those factories interact with. In simpler terms, drivers define
_what_ things you can do; handlers define _how_ to do those things.

## Creating a driver

Rainman drivers are implemented as Modules. They must be extended with
`Rainman::Driver` and use the driver DSL to define their public API. An
example Domain driver might look like this:

```ruby
require 'rainman'

# The Domain module handles creating and deleting domains, and listing
# nameservers
module Domain
  extend Rainman::Driver

  # Register Domain::Abc as a handler. An optional block yields a config hash
  # which can be used to store variables needed by the handler class, in this
  # case a username and password specific for Domain::Abc.
  register_handler :abc |config|
    config.username 'username'
    config.password 'pass'
  end

  # Register Domain::Xyz as a handler.
  register_handler :xyz |config|
    config.username 'username'
    config.password 'pass'
  end

  # Register Domain.create as a public method. An optional block yields a
  # config hash that can be used to specify validations to be run before the
  # method is invoked.
  define_action :create do
    validate :username
  end

  # Register Domain.destroy as a public method
  define_action :destroy

  # Register Domain.namservers.list as a public method
  define_action :list, through: :nameservers
end
```

## Implementing handlers

Driver handlers are implemented as classes. They must be within the namespace
of the driver Module. Using the example above, here are example handlers for
Abc and Xyz:

```ruby
class Domain::Abc
  # Public: Creates a new domain.
  #
  # Returns a Hash.
  def create(params = {})
  end

  # Public: Destroy a domain
  #
  # Returns true or false.
  def destroy(params = {})
  end
end

class Domain::Xyz
  # Public: Creates a new domain.
  #
  # Returns a Hash.
  def create(params = {})
  end

  # Public: Destroy a domain
  #
  # Returns true or false.
  def destroy(params = {})
  end
end
```

The example driver above also defined a `list` action through `nameservers`,
(eg: `Domain.nameservers.list`). To implement this, a Nameservers class is
created within each handler's namespace:

```ruby
class Domain::Abc::Nameserver

  # Public: Lists nameservers for this domain.
  #
  # Returns an Array.
  def list(params = {})
  end
end

class Domain::Xyz::Nameserver

  # Public: Lists nameservers for this domain.
  #
  # Returns an Array.
  def list(params = {})
  end
end
```

## Using a driver

With a driver and handler defined, the driver can now be used in a few
different ways.

### General

A driver's actions are available as singleton methods. By default, actions are
sent to the current handler, or a default handler if a handler is not currently
in use.

```ruby
# Create a domain
Domain.create({})

# Destroy a domain
Domain.destroy({})

# List domain nameservers
Domain.nameservers.list({})
```

### Changing handlers

It is possible to change the handler used at runtime using the `with_handler`
method. The two examples below are identical:

```ruby
Domain.with_handler(:abc) do |driver|
  driver.create
end

Domain.with_handler(:xyz).create
```

### Including drivers in other classes

A driver can be included in another class and it's actions are available as
instance methods.

```ruby
class Service
  include Domain
end

s = Service.new

s.create

s.destroy

s.nameservers.list

s.with_handler(:abc) do |driver|
  driver.create
end

s.with_handler(:zyz).create
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
