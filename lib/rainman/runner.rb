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

    # Public: Gets the handler's driver
    attr_reader :driver

    # Public: Gets the handler config
    attr_reader :config

    # Public: Initialize a runner.
    #
    # handler - A handler Class instance.
    #
    # Examples
    #
    #   Runner.new(current_handler_instance)
    def initialize(name, handler, driver, config = {})
      @name    = name
      @handler = handler
      @driver  = driver
      @config  = config

      @driver.handlers[name] = self
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
