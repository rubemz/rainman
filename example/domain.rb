require 'rainman'

# Load handlers
$:.unshift File.expand_path('..', __FILE__)
require 'domain/enom'
require 'domain/enom/nameservers'
require 'domain/opensrs'
require 'domain/opensrs/nameservers'

# The Domain module will contain all methods for interacting with various
# domain handlers.
module Domain
  extend Rainman::Driver

  register_handler :enom do
    config[:user] = :enom_user
  end

  register_handler :opensrs

  namespace :nameservers, one: :two do
    define_action :list
  end

  define_action :transfer

  set_default_handler :opensrs
end

p Domain.with_handler(:enom).nameservers.list
