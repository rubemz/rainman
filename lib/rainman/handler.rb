module Rainman
  module Handler
    extend self

    def config
      @config ||= {}
    end
  end
end
