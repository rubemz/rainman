module Rainman
  module Driver
    # The Runner class delegates actions to handlers. It runs validations
    # before executing the action.
    #
    # Examples
    #
    #   Runner.new(current_handler_instance).tap do |r|
    #     r.transfer
    #   end
    class Runner
      # Public: Gets the handler Class
      attr_reader :handler

      # Public: Initialize a runner
      #
      # handler - A handler Class instance
      #
      # Examples
      #
      #   Runner.new(current_handler_instance)
      def initialize(handler)
        @handler = handler
      end

      # Public: Get the Symbol name of the handler
      #
      # Returns a Symbol.
      def name
        @handler.class.handler_name
      end

      # Public: Validations to run when a handler's methods are executed
      #
      # Returns the Rainman::Driver::Validations Hash singleton.
      def validations
        @validations ||= handler.class.validations
      end

      # Public: Delegates the given method to the handler
      #
      # method - The method to send to the handler
      # args   - Arguments to be supplied to the method (optional)
      # block  - Block to be supplied to the method (optional)
      #
      # Examples
      #
      #   execute(:register)
      #   execute(:register, { params: [] })
      #   execute(:register, :one, :argument) do
      #     # some code
      #   end
      #
      # Raises MissingParameter if validation fails due to missing parameters.
      #
      # Returns the result of the handler action.
      def execute(method, *args, &block)
        validations[:global].validate!(*args) if validations.has_key?(:global)
        validations[name].validate!(*args) if validations.has_key?(name)

        handler.send(method, *args, &block)
      end

      # Public: Method missing hook used to proxy methods to a handler
      #
      # method - The missing method name
      # args   - Arguments to be supplied to the method (optional)
      # block  - Block to be supplied to the method (optional)
      #
      # Raises NameError if handler does not respond to method.
      #
      # Returns the value of execute.
      def method_missing(method, *args, &block)
        if handler.respond_to?(method)
          execute(method, *args, &block)
        else
          super
        end
      end
    end
  end
end
