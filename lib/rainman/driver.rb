require "forwardable"

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
    # changed for the duration of the block supplied. This is useful to
    # perform actions using multiple handlers without changing defaults.
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
    def with_handler(handler = current_handler)
      begin
        if handler != current_handler
          old_handler = current_handler
          set_current_handler handler
        end

        handlers[current_handler].tap do |h|
          return yield h if block_given?
        end
      ensure
        set_current_handler old_handler if old_handler
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

    # Public: Sets the current handler. Name should be an underscored symbol
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
      base.extend ::Forwardable
      base.def_delegators self, *singleton_methods
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
    # name  - The Symbol handler name.
    # opts  - A Hash containing optional arguments:
    #         :class_name - The class name to use.
    # block - An optional block; if supplied it is set as the runner's
    #         handler_initializer and will be called when the runner
    #         initializes a handler class. Note that the block must return
    #         either the handler class or a handler class instance.
    #
    # Examples
    #
    #   register_handler :bob
    #
    #   register_handler :barry do |barry|
    #     barry.create
    #   end
    #
    # Returns the handler Class.
    def register_handler(name, opts = {}, &block)
      klass = opts.delete(:class_name) || determine_handler_const(name)
      create_handler_predicate_method name
      handlers[name] = Runner.new(name, klass.to_s.constantize, self, opts, &block)
    end

    # Private: Create a new namespace.
    #
    # name  - The Symbol handler name.
    # opts  - Arguments (unused currently).
    # block - A required block used to create actions within the namespace
    #
    # Example
    #
    #   namespace :nameservers do
    #     define_action :list
    #   end
    #
    # Raises Rainman::MissingBlock if called without a block.
    #
    # Returns a Runner.
    def namespace(name, opts = {}, &block)
      raise MissingBlock, :namespace unless block_given?

      namespaces << name

      create_method(name) do
        key = "@#{name}"

        if instance_variable_defined?(key)
          ns = instance_variable_get(key)
        else
          ns = instance_variable_set(key, {})
        end

        unless ns[current_handler]
          mod = Module.new do
            class << self
              attr_accessor :current_handler
            end
            extend ActionMethods
          end

          mod.current_handler = current_handler

          mod.instance_eval(&block)

          klass = "#{self.name}::#{current_handler.to_s.camelize}::#{name.to_s.camelize}"
          klass_opts = with_handler.config.merge(opts)
          ns[current_handler] = Runner.new(name, klass.constantize, mod, klass_opts)
        end

        ns[current_handler]
      end
    end

    # Private: Create predicate method for the given handler.
    #
    # handler_name - The name of the handler
    #
    # Example:
    #
    #   create_handler_predicate_method :blah
    #
    # Creates the method:
    #
    #   blah?
    #
    # Which returns true if the current handler is :blah.
    #
    # Returns a Proc.
    def create_handler_predicate_method(handler_name)
      create_method "#{handler_name}?" do
        current_handler == handler_name
      end
    end

    # Private: Determine where the given constant is.
    #
    # name - The name to check for as an underscored string.
    #
    # First, check that the constant is defined in the current driver's
    # namespace. If it isn't, check if the constant is defined in the global
    # namespace.
    #
    # Raises NameError if the constant cannot be found.
    #
    # Returns a String representing the constant name.
    def determine_handler_const(name)
      cname = name.to_s.camelize

      if self.const_defined? cname
        "#{self.name}::#{cname}"
      elsif Kernel.const_defined? cname
        "::#{cname}"
      else
        raise NameError, "uninitialized constant #{cname.inspect}"
      end
    end

    # These methods are used to create handler actions.
    module ActionMethods
      # Public: Namespaces that have been registered.
      #
      # Returns an Array of Symbols.
      def namespaces
        @namespaces ||= []
      end
      public :namespaces

      # Public: The actions the current driver has registered.
      #
      # Returns an Array of Symbols.
      def actions
        @actions ||= []
      end
      public :actions

      # Private: Define a new action.
      #
      # name - The Symbol handler name.
      # opts - A Hash of options used for creating the method:
      #        :delegate_to - The method name to run on the handler. Defaults
      #                       to the action's name.
      #        :alias       - If supplied, an alias will be created for the
      #                       defined method.
      #
      # If a block is supplied, it is used to filter parameters when the
      # action is invoked.
      #
      # Examples
      #
      #   define_action :create
      #
      #   define_action :destroy, :alias => :delete
      #
      #   define_action :list do |*args|
      #     args.delete_if &:nil?
      #   end
      #
      # Returns a Proc.
      def define_action(name, opts = {}, &blk)
        actions << name

        create_method(name) do |*args, &block|
          hargs  = blk ? blk.call(*args) : args
          method = opts[:delegate_to] || name
          with_handler.send(method, *hargs, &block)
        end

        alias_method opts[:alias], name if opts[:alias]
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
        if respond_to?(method, true)
          raise AlreadyImplemented, "#{inspect}::#{method}"
        else
          define_method(method, *args, &block)
        end
      end
    end

    include ActionMethods
  end
end
