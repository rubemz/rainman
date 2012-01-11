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
    # Public: Gets the handler Class.
    attr_reader :handler

    # Public: Initialize a runner.
    #
    # handler - A handler Class instance.
    #
    # Examples
    #
    #   Runner.new(current_handler_instance)
    def initialize(handler)
      @handler = handler
    end

    # Public: Get the Symbol name of the handler.
    #
    # Returns a Symbol.
    def name
      handler.class.handler_name
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
      context.send(method, *args, &block)
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
      if handler.respond_to?(method)
        execute(handler, method, *args, &block)
      elsif parent_klass.respond_to?(method)
        if parent_klass.instance_methods.map(&:to_sym).include?(method) && !parent_klass.namespaces.include?(method)
          raise Rainman::MissingHandlerMethod.new(:method => method, :class => handler.class.name)
        else
          execute(parent_klass, method, *args, &block)
        end
      else
        super
      end
    end
  end
end
