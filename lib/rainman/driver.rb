require 'forwardable'
require 'active_support/core_ext/string'

module Rainman
  module Driver
    Config = {}
    Validations = { :global => Option.new(:global) }

    # Executes the requested handler method after validating
    #
    # Examples
    #
    #   r = Runner.new(:domain, current_handler_instance)
    #   r.transfer #=> Runs current_handler_instance.send(:transfer)
    class Runner
      # Public: Gets/Sets the Symbol name of the handler
      attr_accessor :name

      # Public: Gets/Sets the handler Class
      attr_accessor :handler

      # Public: Initialize a runner
      #
      # name    - A Symbol representing the name of the handler
      # handler - A handler Class instance
      #
      # Examples
      #
      #   Runner.new(:domain, current_handler_instance)
      def initialize(name, handler)
        @handler = handler
        @name    = name
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
      def execute(method, *args, &block)
        validations[:global].validate!(*args)
        validations[name].validate!(*args) if validations.has_key?(name)

        handler.send(method, *args, &block)
      end

      # Public: Method missing hook used to proxy methods to a handler
      #
      # method - The missing method name
      # args   - Arguments to be supplied to the method (optional)
      # block  - Block to be supplied to the method (optional)
      def method_missing(method, *args, &block)
        if handler.respond_to?(method)
          execute(method, *args, &block)
        else
          super
        end
      end
    end

    # Public: Temporarily change a driver's current handler. If a block is
    # supplied, it will be evaluated. This is useful to perform actions using
    # multiple handlers without changing defaults.
    #
    # name - The Symbol name of the handler to use.
    #
    # Examples
    #
    #   with_handler(:enom).transfer
    #
    #   with_handler(:enom) do |handler|
    #     handler.transfer
    #   end
    #
    # Yields a Runner instance if a block is given.
    #
    # Returns a Runner instance.
    def with_handler(name)
      old_handler = current_handler

      begin
        set_current_handler name
        Runner.new(name, current_handler_instance).tap do |runner|
          yield runner if block_given?
        end
      ensure
        set_current_handler old_handler
      end
    end

    # DSL methods are made available as class methods in Driver modules
    module DSL
      # These methods are available in handler modules as class methods
      module PublicMethods
        # Public: Alias for the Config hash
        #
        # Returns the Rainman::Driver::Config Hash singleton.
        def config
          Config
        end

        # Public: Alias for the Validations hash
        #
        # Returns the Rainman::Driver::Validations Hash singleton.
        def validations
          Validations
        end
      end

      # Add PublicMethods to the DSL so it's automatically available to
      # anything that is extended with Rainman::Driver
      include PublicMethods

      # Public: Registered handlers
      #
      # Keys are the handler name (eg: :my_handler); values are the handler
      # class (eg: MyHandler)
      #
      # Raises RuntimeError if a lookup fails.
      #
      # Returns a Hash.
      def handlers
        @handlers ||= Hash.new { |hash, key| raise "Invalid handler, '#{key}'" }
      end

      private

      # Private: Included hook; this is invoked when a Driver module is
      # included in another class. It sets up delegation so that the including
      # class can access a Driver's singleton methods as instance methods.
      #
      # base - The Module/Class that included this module
      #
      # Example
      #
      #   class Service
      #     include Domain
      #   end
      #
      #   s = Service.new
      #   s.transfer #=> calls Domain.transfer
      #
      # Returns nothing.
      def included(base)
        base.extend(Forwardable)
        base.def_delegators self, *(instance_methods + [:with_handler])
      end

      # Private: Sets the default handler used for this Driver
      #
      # name - The Symbol name to set as the default handler. Should be a key
      #        from handlers.
      #
      # Raises RuntimeError if a handler cannot be found.
      #
      # Returns the Symbol name
      def set_default_handler(name)
        @default_handler_class = handlers[name]
        @default_handler       = name
      end

      # Private: Get the default handler used for this Driver
      #
      # Returns the Symbol name of this Driver's default handler
      def default_handler
        @default_handler
      end

      # Private: Get the current handler in use by this Driver.
      #
      # Returns the Symbol name of the current handler, or default handler if
      # a current handler is not set.
      def current_handler
        @current_handler || @default_handler
      end

      # Private: Get the current handler class.
      #
      # Returns the Class constant of the current handler, or the default
      # handler if a current handler is not set.
      def current_handler_class
        @current_handler_class || @default_handler_class
      end

      # Private: A hash containing handler instances. This prevents handlers
      # from being initialized multiple times in a single session.
      #
      # Returns a Hash containing instances of handlers that have been
      # initialized.
      def handler_instances
        @handler_instances ||= {}
      end

      # Private: Get or set an instance of the current handler class. This
      # method stores the instance in handler_instances, and should be used
      # instead of manually initializing handlers.
      #
      # Returns an instance of the current handler class.
      def current_handler_instance
        handler_instances[current_handler] ||= current_handler_class.new
      end

      # Private: Sets the current handler. Name should be an underscored symbol
      # representing a class name in the current context
      #
      # name - The Symbol name of the handler to use. Can be set to nil to
      #        clear the current handler.
      #
      # Example
      #
      #   set_current_handler :my_handler #=> sets handler to MyHandler
      #   set_current_handler nil         #=> clears handler
      #
      # Returns the Symbol name of the current handler or nothing.
      def set_current_handler(name)
        if name.nil?
          @current_handler_class = @current_handler = nil
        else
          @current_handler_class = handlers[name]
          @current_handler       = name
        end
      end

      # Private: Register a handler for use with the current driver
      #
      # name - The Symbol handler name
      # args - Arguments (unused currently)
      #
      # Example
      #
      #     register_handler :bob
      #
      # Yields the handler class config if a block is given.
      #
      # Returns the handler Class.
      def register_handler(name, *args)
        klass = "#{self.name}::#{name.to_s.camelize}".constantize
        klass.extend(DSL::PublicMethods)

        klass.config[name] = {}
        yield klass.config[name] if block_given?
        handlers[name] = klass
      end

      # Private: Create a new namespace
      #
      # name - The Symbol handler name
      # args - Arguments (unused currently)
      #
      # Yields the handler class config if a block is given.
      #
      # Returns a Proc.
      def namespace(name, *args, &block)
        config[name] = args

        define_method(name) do
          name = __method__.to_s
          key = "@#{name}"

          unless ivar = instance_variable_get(key)
            ivar = instance_variable_set(key, {})
          end

          klass = current_handler_class.const_get(name.camelize)
          puts "Config: #{current_handler_class.config}"
          klass.extend(DSL)

          ivar[current_handler] ||= klass.new
          ivar[current_handler]
        end
      end

      # Private: Define a new action
      #
      # name - The Symbol handler name
      # opts - Options (unused currently)
      #
      # Returns a Proc.
      def define_action(name, *opts)
        yield config[name] if block_given?

        define_method(name) do |*args, &block|
          puts "Config: #{current_handler_instance.class.config}"
          runner = Runner.new(current_handler, current_handler_instance)
          runner.send(name, *args, &block)
        end
      end
    end # module DSL

    def self.extended(base)
      base.extend(base)
      base.extend(DSL)
    end
  end
end
