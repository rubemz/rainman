require 'rainman'

# Default is :autoload. You can also use :require or :none
Rainman.load_strategy :autoload

# Autoload all drivers in this path
Rainman.set_driver_path  '/path/to/drivers'

# Load one driver
Rainman.load_driver  'my_driver'

# Load a driver with a specific handler
Rainman.load_driver  'other/something'

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
    attr_reader

    def initialize
      @config =
    end

    def register(opts = {})

    end
  end
end


# Using the driver and handler
class MyClass
  # Actions are mixed in
  Rainman.include_driver :domain, :default_handler => :enom
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
  # Actions are mixed in with a prefix of 'domain'
  Rainman.include_driver :domain, :prefix => 'domain', :default_handler => :opensrs
end

# Using :default_handler of :opensrs
my_class.domain.register(:domain => 'test.com')
my_class.domain.nameservers.contacts

# Using the :opensrs handler
my_class.domain.with_handler :enom do |driver|
  driver.register(:domain => 'test.com')
end
