require "rainman/version"
require 'active_support/core_ext/string'

module Rainman
  autoload :Exceptions, 'rainman/exceptions'
  autoload :Stash,      'rainman/stash'
  autoload :Option,     'rainman/option'
  autoload :Driver,     'rainman/driver'
  autoload :Handler,    'rainman/handler'

  extend self

  def load_strategy(strategy = nil)
    if strategy
      if [:require, :autoload].include?(strategy)
        @load_strategy = strategy
      else
        raise ":#{strategy} is not a recognized strategy"
      end
    else
      @load_strategy ||= :autoload
    end
  end
end
