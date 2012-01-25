module Rainman
  # The Runner class acts as a proxy between a driver and it's handlers. Each
  # handler will have one runner. Method calls are sent to the runner and
  # delegated to the handler.
  #
  # Examples
  #
  #   Runner.new(:domain, DomainHandler, Domain).tap do |r|
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
    # name    - The Symbol name of this Runner. Used to lookup a Runner from
    #           within a driver.
    # handler - A handler Class/Module.
    # driver  - A driver Module.
    # config  - An optional Hash containing config parameters available
    #           throughout a Runner instance.
    #
    # If a block is given, it is used to initialize the handler class.
    #
    # Examples
    #
    #   Runner.new(:domain, DomainHandler, Domain)
    #
    #   Runner.new(:domain, DomainHandler, Domain) do |dom_handler|
    #     dom_handler.create_domain
    #   end
    def initialize(name, handler, driver, config = {}, &block)
      @name    = name
      @handler = handler
      @driver  = driver
      @config  = config

      @handler_initializer = block if block_given?
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
      if handler_instance.respond_to?(method)
        if driver.actions.include?(method)
          handler_instance.send(method, *args, &block)
        else
          raise UnregisteredAction, method
        end
      elsif driver.respond_to?(:namespaces) && driver.namespaces.include?(method)
        driver.send(method)
      else
        super
      end
    end

    private

    # Private: Get the handler's initializer. This can be a proc or non-nil
    # object. Defaults to true.
    def handler_initializer
      @handler_initializer ||=
        config.has_key?(:initialize) ? config[:initialize] : true
    end

    # Private: Creates/returns a new handler instance.
    #
    # If the handler_initializer is a proc, it is called with the handler
    # class as a parameter. This allows the handler to be initialized with
    # methods other than #new.
    #
    # If the handler_initializer is non-nil (but not a proc), the handler is
    # initialized by calling handler.new.
    #
    # If the handler_initializer is falsey (nil or false), the handler is
    # **not** initialized. Instead, the handler class itself is returned. This
    # is useful for using handlers that are singleton modules/classes.
    def handler_instance
      @handler_instance ||= if handler_initializer.respond_to?(:call)
                              handler_initializer.call(handler)
                            elsif handler_initializer
                              handler.new
                            else
                              handler
                            end
    end
  end
end
