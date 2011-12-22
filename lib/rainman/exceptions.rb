module Rainman
  # This module contains exceptions that may be thrown by Rainman.
  module Exceptions
    # AlreadyImplemented is raised when attempting to create a driver action
    # that has already been defined.
    class AlreadyImplemented < StandardError
      def initialize(method)
        super "Method #{method.inspect} already exists!"
      end
    end

    # InvalidHandler is raised when attempting to access a handler that has
    # not yet been registered.
    class InvalidHandler < StandardError
      def initialize(handler)
        super "Handler #{handler.inspect} is invalid! Maybe you need to " <<
              "call 'register_handler #{handler.inspect}'?"
      end
    end
  end
end
