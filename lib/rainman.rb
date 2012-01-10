require "rainman/version"
require "rainman/exceptions"
require "rainman/option"
require "rainman/handler"
require "rainman/runner"
require "rainman/driver"
require "rainman/configuration"

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
