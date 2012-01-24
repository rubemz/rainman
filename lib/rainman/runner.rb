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

    # Public: Gets the handler config
    attr_reader :config

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

    # Public: Initialize a runner.
    #
    # handler - A handler Class instance.
    #
    # Examples
    #
    #   Runner.new(current_handler_instance)
    def initialize(name, handler, parent = nil, config = {})
      @name    = name
      @handler = handler
      @parent  = parent
      @config  = config

      self.class.handlers[name] = self
    end

    # Internal: Method missing hook used to proxy methods to a handler.
    #
    # method - The missing method name.
    # args   - Arguments to be supplied to the method (optional).
    # block  - Block to be supplied to the method (optional).
    #
    # Raises NameError if handler does not respond to method.
    #
    # Returns the value of the method call.
    def method_missing(method, *args, &block)
      init = config.has_key?(:initialize) ? config[:initialize] : true
      hand = init ? handler.new : handler

      if hand.respond_to?(method)
        hand.send(method, *args, &block)
      else
        super
      end
    end
  end
end
