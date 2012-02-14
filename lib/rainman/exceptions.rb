module Rainman
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

  # NoHandler is raised when attempting to do something that needs a handler,
  # but no default or current handler can be found.
  class NoHandler < StandardError
    def initialize
      super "No handler is set! Maybe you need to " <<
            "call 'set_default_handler'?"
    end
  end

  # MissingParameter is raised when trying to send a request to a runner that
  # is missing parameters/arguments.
  class MissingParameter < StandardError
    def initialize(param)
      super "Missing parameter #{param.inspect}!"
    end
  end

  # MissingBlock is raised when trying to run an action that is missing a
  # required block parameter.
  class MissingBlock < LocalJumpError
    def initialize(method)
      super "Can't call #{method.inspect} without a block!"
    end
  end

  # UnregisteredAction is raised when trying to run an handler action that
  # hasn't been registered.
  class UnregisteredAction < StandardError
    def initialize(method)
      super "Unregistered action, #{method.inspect}"
    end
  end
end
