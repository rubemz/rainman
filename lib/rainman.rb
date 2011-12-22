require "rainman/version"
require "rainman/exceptions"
require "rainman/stash"
require "rainman/option"
require "rainman/driver"
require "rainman/handler"

module Rainman
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
