module Rainman
  # The Handler module contains methods that are added to handler classes at
  # runtime. They are available as class methods.
  module Handler
    # Public: Alias for the Config hash.
    #
    # Returns the Rainman::Driver::Config Hash singleton.
    def config
      @config
    end

    # Public: The name of this handler.
    #
    # Returns a Symbol.
    def handler_name
      @handler_name
    end

    # Public: Get the the handler's parent_klass.
    #
    # Returns Rainman::Driver.self
    def parent_klass
      @parent_klass
    end

    # These instance methods are available to handler instances.
    module InstanceMethods
      # Public: A Runner is automatically available to handler instances.
      #
      # Returns a Rainman::Runner.
      def runner
        @runner ||= Rainman::Runner.new(self)
      end
    end

    # Public: Extended hook; this adds the InstanceMethods module to handler
    # classes.
    #
    # base - The Module/Class that was extended with this module.
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end
  end
end
