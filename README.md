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

  # Register Domain::Abc as a handler.
  register_handler :abc

  # Register Domain::Xyz as a handler.
  register_handler :xyz

  # Register Domain.create as a public method
  define_action :create

  # Register Domain.destroy as a public method; Alias Domain.delete to it
  define_action :destroy, :alias => :delete

  # Register Domain.namservers.list as a public method
  namespace :nameservers do
    define_action :list
  end
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

The example driver above also defined `nameservers` namespace with a `list`
action (eg: `Domain.nameservers.list`). To implement this, a Nameservers class
is created within each handler's namespace:

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

## Handler setup
If your handler requires any sort of setup that can't be handled in your
initialize method (e.g. you're subclassing and can't override
initialize), you can define a setup_handler method. Rainman will
automatically call this method for you after the class is initialized.

```ruby
class Domain::Abc
  attr_accessor :config

  def initialized
    @config = { :username => 'username', :password => 'password' }
  end
end

class Domain::Xyz < Domain::Abc
  def setup_handler
    @config[:username] = 'other'
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
Domain.delete({})

# List domain nameservers
Domain.nameservers.list({})
```

### Changing handlers

It is possible to change the handler used at runtime using the `with_handler`
method. This method temporarily changes the current handler. This means, if
you have a default handler set, and use `with_handler`, that default handler
is preserved.

```ruby
Domain.with_handler(:abc) do |driver|
  # Here, current_handler is now set to :abc
  driver.create
end
```

You can also change the current handler for the duration of your code/session.

```ruby
Domain.set_current_handler :xyz
Domain.create # create an :xyz domain

Domain.set_current_handler :abc
Domain.create   # create an :abc domain
Domain.transfer # transfer an :abc domain
```

It is highly suggested you stick to using `with_handler` unless you have a
reason.

### Including drivers in other classes

A driver can be included in another class and its actions are available as
instance methods.

```ruby
class Service
  include Domain
end

s = Service.new

s.create

s.destroy
s.delete

s.nameservers.list

s.with_handler(:abc) do |handler|
  handler.create
end

s.set_current_handler :xyz
s.create
```

If you want to namespace a driver in another class, it's as easy as:

```ruby
class Service
  def domain
    Domain
  end
end

s = Service.new

s.domain.create

s.domain.destroy
s.domain.delete

s.domain.nameservers.list

s.domain.with_handler(:abc) do |handler|
  handler.create
end

s.domain.set_current_handler :xyz
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
