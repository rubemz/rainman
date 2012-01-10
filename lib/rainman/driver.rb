require "forwardable"
require "active_support/core_ext/string"
require "active_support/core_ext/array"

module Rainman
  # The Rainman::Driver module contains methods for defining Drivers and
  # proxying their associated actions to the appropriate handlers.
  module Driver
    # Public: Extended hook; this is run when a module extends itself with
    # the Rainman::Driver module.
    def self.extended(base)
      all << base
      base.extend(base)
    end

    # Public: Get a list of all Drivers (eg: Modules that are extended with
    # Rainman::Driver).
    #
    # Returns an Array.
    def self.all
      @all ||= []
    end

    # Public: A Hash that stores configuration variables that can be
    # used by handlers and actions in a Driver.
    #
    # Returns a Hash.
    def config
      @config ||= Configuration.data
    end

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
    def handlers
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
    def with_handler(name, &block)
      raise MissingBlock, :with_handler unless block_given?

      old_handler = current_handler

      begin
        set_current_handler name
        yield current_handler_instance.runner
      ensure
        set_current_handler old_handler
      end
    end

    # Public: Sets the default handler used for this Driver.
    #
    # name - The Symbol name to set as the default handler. Should be a key
    #        from handlers.
    #
    # Returns the Symbol name.
    def set_default_handler(name)
      @default_handler = name
    end

    # Public: Get the default handler used for this Driver.
    #
    # Returns the Symbol name of this Driver's default handler.
    def default_handler
      @default_handler
    end

    private

    # Private: Included hook; this is invoked when a Driver module is
    # included in another class. It sets up delegation so that the including
    # class can access a Driver's singleton methods as instance methods.
    #
    # base - The Module/Class that included this module.
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
    # representing a class name in the current context.
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

    # Private: Register a handler for use with the current Driver.
    #
    # If a block is given it is evaluated within the context of the handler
    # Class.
    #
    # name - The Symbol handler name.
    # opts - A Hash containing optional arguments:
    #        :class_name - The class name to use.
    #
    # Examples
    #
    #   register_handler :bob
    #
    #   register_handler :pop do
    #     config[:username] = 'username'
    #   end
    #
    # Returns the handler Class.
    def register_handler(name, opts = {}, &block)
      opts.reverse_merge!(
        :class_name => "#{self.name}::#{name.to_s.camelize}"
      )

      klass = opts[:class_name].constantize

      handlers[name] = inject_handler_methods(klass, name.to_sym, &block)
    end

    # Private: Define a new action.
    #
    # name - The Symbol handler name.
    # opts - Options (unused currently).
    #
    # Example
    #
    #   define_action :blah
    #
    # Returns a Proc.
    def define_action(name, opts = {})
      create_method(name) do |*args, &block|
        current_handler_instance.runner.send(name, *args, &block)
      end
    end

    # Private: Create a new namespace.
    #
    # name - The Symbol handler name.
    # opts - Arguments (unused currently).
    #
    # Yields the handler class config if a block is given.
    #
    # Returns a Proc.
    def namespace(name, opts = {}, &block)
      # config_key = "#{self.name}##{name}"
      # klass_config = config[config_key] = opts

      create_method(name) do
        name = __method__.to_sym
        key  = "@#{name}"

        if instance_variable_defined?(key)
          ns = instance_variable_get(key)
        else
          ns = instance_variable_set(key, {})
        end

        unless ns[current_handler]
          klass = current_handler_instance.class.const_get(name.to_s.camelize)

          ns[current_handler] = inject_handler_methods(klass, name).new
        end

        ns[current_handler].runner
      end
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

    # Private: Injects Handler methods into the given class/module.
    #
    # base           - The base Class/Module.
    # handler_name   - The Symbol name of the handler class.
    # block          - Optional Proc that will be evaluated within the context
    #                  of the base's singleton class.
    #
    # Example
    #
    #   inject_handler_methods(SomeHandler, :some_handler)
    #
    # Returns base Class/Module.
    def inject_handler_methods(base, handler_name, &block)
      base.extend(Handler)
      base.instance_variable_set(:@handler_name, handler_name)
      base.instance_variable_set(:@parent_klass, self)
      conf = base.instance_variable_set(:@config, Configuration.new(handler_name))
      instance_eval_value(:config, conf, &block)
      base
    end

    # Private: Creates and instance_evals an anonymous class with key available
    # as an instance method.
    #
    # Example
    #
    #   def blah(&block)
    #     instance_eval_value(:name, 'Josh', &block)
    #   end
    #
    #   blah do
    #     name # in this context, name is == 'Josh'
    #   end
    def instance_eval_value(key, value, &block)
      klass = Class.new
      klass.send(:attr_reader, key)
      klass_i = klass.new
      klass_i.instance_variable_set("@#{key}", value)
      klass_i.instance_eval(&block) if block_given?
    end
  end
end
