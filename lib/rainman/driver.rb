require 'forwardable'
require 'active_support/core_ext/string'

module Rainman
  module Driver
    Config = {}
    Validations = { :global => Option.new(:global) }

    # Executes the requested handler method after validating
    class Runner
      attr_accessor :handler, :name, :validations

      def initialize(name, handler, validations)
        @handler = handler
        @name    = name
        @validations = validations
      end

      def execute(method, *args, &block)
        validations[:global].validate!(*args)
        validations[name].validate!(*args) if validations.has_key?(name)

        handler.send(method, *args, &block)
      end

      def method_missing(method, *args, &block)
        if handler.respond_to?(method)
          execute(method, *args, &block)
        else
          super
        end
      end
    end

    # Return or yield an instance of the given handler.
    #
    # Examples:
    #
    #     with_handler(:enom).transfer
    #
    #     with_handler(:enom) do |handler|
    #       handler.transfer
    #     end
    def with_handler(name)
      old_handler = current_handler

      begin
        set_current_handler name
        runner = Runner.new(name, current_handler_instance, validations)
        yield runner if block_given?
        runner
      ensure
        set_current_handler old_handler
      end
    end

    module DSL
      def included(base)
        base.extend(Forwardable)
        base.def_delegators self, *(instance_methods + [:with_handler])
      end

      def config
        Config
      end

      def validations
        Validations
      end

      def set_default_handler(name)
        @default_handler_class = handlers[name]
        @default_handler       = name
      end

      def default_handler
        @default_handler
      end

      # Returns the name of the current handler, as an underscored symbol
      #
      # Example:
      #     current_handler #=> :my_handler
      def current_handler
        @current_handler || @default_handler
      end

      # Returns the current handler class (as a constant)
      def current_handler_class
        @current_handler_class || @default_handler_class
      end

      # A hash store containing instances of any handlers invoked
      def handler_instances
        @handler_instances ||= {}
      end

      # Returns an instance of the current handler class
      def current_handler_instance
        handler_instances[current_handler] ||= current_handler_class.new
      end

      # Sets the current handler. Name should be an underscored symbol
      # representing a class name in the current context
      #
      # Example:
      #     set_current_handler :my_handler
      def set_current_handler(name)
        if name.nil?
          @current_handler_class = @current_handler = nil
        else
          @current_handler_class = handlers[name]
          @current_handler       = name
        end
      end

      # A hash that stores handlers
      #
      # Keys are the handler name (eg: :my_handler); values are the handler class
      # (eg: MyHandler)
      def handlers
        @handlers ||= Hash.new { |hash, key| raise "Invalid handler, '#{key}'" }
      end

      # Register a handler for use with the current driver
      #
      # Example:
      #     register_handler :bob
      def register_handler(name, *args, &block)
        klass = "#{self.name}::#{name.to_s.camelize}".constantize

        # klass.extend(Rainman::Handler)
        klass.instance_eval do
          def config
            Config
          end
        end
        klass.config[name] = {}
        yield klass.config[name] if block_given?
        handlers[name] = klass
      end

      # Create a new namespace
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

      # Define a new action
      def define_action(name, *args, &block)
        define_method(name) do |*args|
          puts "Config: #{current_handler_instance.class.config}"
          runner = Runner.new(current_handler, current_handler_instance, validations)
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
