module Rainman
  # The Runner class delegates actions to handlers. It runs validations
  # before executing the action.
  #
  # Examples
  #
  #   Runner.new(current_handler_instance).tap do |r|
  #     r.transfer
  #   end
  class Runner
    # Public: Get the handler name (as an underscored Symbol).
    attr_reader :name

    # Public: Gets the handler Class.
    attr_reader :handler

    # Public: Registered handlers.
    #
    # Keys are the handler name (eg: :my_handler); values are the handler
    # class (eg: MyHandler).
    #
    # Raises NoHandler if an attempt to access a key of nil is made, (eg:
    # handlers[nil]).
    #
    # Raises InvalidHandler if an attempt to access an invalid key is made.
    #
    # Returns a Hash.
    def self.handlers
      @handlers ||= Hash.new do |hash, key|
        if key.nil?
          raise NoHandler
        else
          raise InvalidHandler, key
        end
      end
    end

    # Public: Temporarily change a Driver's current handler. The handler is
    # changed for the duration of the block supplied. This is useful to perform
    # actions using multiple handlers without changing defaults.
    #
    # name - The Symbol name of the handler to use.
    #
    # Example
    #
    #   with_handler(:enom) do |handler|
    #     handler.transfer
    #   end
    #
    # Yields a Runner instance if a block is given.
    #
    # Returns a Runner instance or the result of a block.
    def self.with_handler(name)
      raise MissingBlock, :with_handler unless block_given?

      yield handlers[name]
    end

    # Public: Initialize a runner.
    #
    # handler - A handler Class instance.
    #
    # Examples
    #
    #   Runner.new(current_handler_instance)
    def initialize(name, handler, parent, config = {})
      @name    = name
      @handler = handler
      @parent  = parent
      @config  = config

      self.class.handlers[name] = self
    end

    # Public: Get the handler's parent_klass
    #
    # Returns Rainman::Driver.self
    def parent_klass
      handler.class.parent_klass
    end

    # Public: Delegates the given method to the handler.
    #
    # context - Set the context for the method (class/instance)
    # method  - The method to send to the handler.
    # args    - Arguments to be supplied to the method (optional).
    # block   - Block to be supplied to the method (optional).
    #
    # Examples
    #
    #   execute(handler, :register)
    #   execute(handler.parent_class, :register, { params: [] })
    #   execute(handler, :register, :one, :argument) do
    #     # some code
    #   end
    #
    # Raises MissingParameter if validation fails due to missing parameters.
    #
    # Returns the result of the handler action.
    def execute(context, method, *args, &block)
      # verify params here
      if config.has_key?(:initialize) && config[:initialize]
        c = context.new
      else
        c = context
      end

      c.send(method, *args, &block)
    end

    # Internal: Method missing hook used to proxy methods to a handler.
    #
    # method - The missing method name.
    # args   - Arguments to be supplied to the method (optional).
    # block  - Block to be supplied to the method (optional).
    #
    # Raises NameError if handler does not respond to method.
    #
    # Returns the value of execute.
    def method_missing(method, *args, &block)
      p name
      p method
      # if handler.respond_to?(method)
      #   execute(handler, method, *args, &block)
      # elsif parent_klass.respond_to?(method)
      #   execute(parent_klass, method, *args, &block)
      # else
      #   super
      # end
    end
  end
end
