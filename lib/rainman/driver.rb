require "rainman/driver/runner"
require "forwardable"
require "active_support/core_ext/string"
require "active_support/core_ext/array"

module Rainman
  module Driver
    # Public: Extended hook; this is run when a module extends itself with
    # the Rainman::Driver module.
    def self.extended(base)
      all << base
      base.extend(base)
    end

    # Public: Get a list of all Drivers (eg: Modules that are extended with
    # Rainman::Driver)
    #
    # Returns an Array.
    def self.all
      @all ||= []
    end

    # Public: A Hash that stores configuration variables that can be
    # used by handlers and actions in a driver.
    #
    # Returns a Hash.
    def config
      @config ||= {}
    end

    # Public: Registered handlers
    #
    # Keys are the handler name (eg: :my_handler); values are the handler
    # class (eg: MyHandler)
    #
    # Raises RuntimeError if a lookup fails.
    #
    # Returns a Hash.
    def handlers
      @handlers ||= Hash.new { |hash, key| raise InvalidHandler, key }
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
    # Returns a Runner instance or the result of a block.
    def with_handler(name)
      old_handler = current_handler

      begin
        set_current_handler name
        current_handler_instance.runner.tap do |runner|
          return yield runner if block_given?
        end
      ensure
        set_current_handler old_handler
      end
    end

    # Public: Sets the default handler used for this Driver
    #
    # name - The Symbol name to set as the default handler. Should be a key
    #        from handlers.
    #
    # Raises RuntimeError if a handler cannot be found.
    #
    # Returns the Symbol name
    def set_default_handler(name)
      @default_handler = name
    end

    # Public: Get the default handler used for this Driver
    #
    # Returns the Symbol name of this Driver's default handler
    def default_handler
      @default_handler
    end

    # HandlerMethods are added to handler classes at runtime. They are
    # available as class methods.
    module HandlerMethods
      # Public: Alias for the Config hash.
      #
      # Returns the Rainman::Driver::Config Hash singleton.
      def config
        @config
      end

      # Public: Alias for the Validations hash.
      #
      # Returns the Rainman::Driver::Validations Hash singleton.
      def validations
        config[:validations] ||= {}
      end

      # Public: The name of this handler.
      #
      # Returns a Symbol.
      def handler_name
        @handler_name
      end

      module InstanceMethods
        def runner
          @runner ||= Runner.new(self)
        end
      end

      def self.extended(base)
        base.send(:include, InstanceMethods)
      end
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
      base.extend(::Forwardable)
      base.def_delegators self, *singleton_methods
      # base.def_delegators self, *(instance_methods + [
      #   :with_handler, :handlers, :default_handler, :set_default_handler
      # ])
    end

    # Private: A hash containing handler instances. This prevents handlers
    # from being initialized multiple times in a single session.
    #
    # Returns a Hash containing instances of handlers that have been
    # initialized.
    def handler_instances
      @handler_instances ||= {}
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
      @current_handler = name
    end

    # Private: Get or set an instance of the current handler class. This
    # method stores the instance in handler_instances, and should be used
    # instead of manually initializing handlers.
    #
    # Returns an instance of the current handler class.
    def current_handler_instance
      handler_instances[current_handler] ||= handlers[current_handler].new
    end

    # Private: Get the current handler in use by this Driver.
    #
    # Returns the Symbol name of the current handler, or default handler if
    # a current handler is not set.
    def current_handler
      @current_handler || @default_handler
    end

    # Private: Register a handler for use with the current driver
    #
    # name - The Symbol handler name
    # opts - A Hash containing optional arguments:
    #        :class_name - The class name to use
    #
    # Examples
    #
    #   register_handler :bob
    #
    # Yields the handler class config if a block is given.
    #
    # Returns the handler Class.
    def register_handler(name, opts = {})
      opts.reverse_merge!(
        :class_name => "#{self.name}::#{name.to_s.camelize}"
      )

      klass = opts[:class_name].constantize

      klass.extend(HandlerMethods)
      klass.instance_variable_set(:@handler_name, name.to_sym)

      klass_config = config[name.to_sym] = {}
      klass.instance_variable_set(:@config, klass_config)

      yield klass_config if block_given?

      handlers[name] = klass
    end

    # Private: Define a new action
    #
    # name - The Symbol handler name
    # opts - Options (unused currently)
    #
    # Example
    #
    #   define_action :blah do
    #     # code to run
    #   end
    #
    # Returns a Proc.
    def define_action(name, *opts)
      config[name] = {}

      yield config[name] if block_given?

      create_method(name) do |*args, &block|
        current_handler_instance.runner.send(name, *args, &block)
      end
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
      # config[name] = args

      # define_method(name) do
      #   name = __method__.to_s
      #   key = "@#{name}"

      #   unless ivar = instance_variable_get(key)
      #     ivar = instance_variable_set(key, {})
      #   end

      #   klass = current_handler_class.const_get(name.camelize)
      #   puts "Config: #{current_handler_class.config}"
      #   klass.extend(DSL)

      #   ivar[current_handler] ||= klass.new
      #   ivar[current_handler]
      # end
    end

    # Private: Creates a new method.
    #
    # method - The method name.
    # args   - Arguments to be supplied to the method (optional).
    # block  - Block to be supplied to the method (optional).
    #
    # Examples
    #
    #   create_method :blah do
    #     # code to execute
    #   end
    #
    # Raises Rainman::AlreadyImplemented if the method already exists.
    #
    # Returns a Proc.
    def create_method(method, *args, &block)
      if respond_to?(method)
        raise AlreadyImplemented, method
      else
        define_method(method, *args, &block)
      end
    end
  end
end
