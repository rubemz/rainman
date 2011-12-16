require 'forwardable'

module Rainman
  module Driver
    # Array of known handlers
    def handlers
      @handlers ||= []
    end

    # Action options
    def options
      @options ||= {:global => Option.new(:global)}
    end

    # Driver actions
    def actions
      @actions ||= []
    end

    def default_handler(value = :none)
      if value == :none
        @default_handler
      else
        @default_handler = value
      end
    end

    def current_handler
      @current_handler ||= default_handler
    end

    # Registers a handler with the driver
    def register_handler(name, &block)
      add_handler(name)
      name  = name.to_s
      klass = "#{self.name}::#{name.to_s.camelize}"
      if self::const_defined?(name.camelize)
        k = klass.constantize.extend(Rainman::Handler)
        yield k.config if block_given?
      else
        raise "Unknown handler '#{self}::#{name.camelize}'"
      end
    end

    # Adds a driver method
    def define_action(name, &block)
      options[name] ||= Option.new(name)
      actions << name unless actions.include?(name)

      yield options[name] if block_given?

      (class << self; self; end).class_eval do
        define_method(name) do |*args|
          options[:global].validate!(*args)
          options[name].validate!(*args)

          if current_handler
            with_handler(current_handler).send(name, *args)
          else
            raise "no handler specified"
          end
        end
      end
    end

    def add_option_all(opts = {})
      options[:global].add_option opts
    end

    def with_handler(name, &block)
      raise ":#{name} is not a valid handler" unless handlers.include?(name)
      klass = "#{self.name}::#{name.to_s.camelize}".constantize.new
      yield klass if block_given?
      klass
    end

    def with_options(opts = {})
      self.default_handler(opts[:default_handler]) if opts[:default_handler]
      @prefix = opts[:prefix]
      self
    end

    def included(base)
      base.extend(Forwardable)
      if @prefix
        method_name = @prefix
        target      = self
        base.class_eval do
          define_method(method_name) { target }
        end
      else
        base.def_delegators self, *actions
      end
    end

  private
    # Records the driver handler in the @handlers array
    def add_handler(name)
      if handlers.include?(name)
        raise "Handler already registered '#{self}::#{name.to_s.camelize}'"
      else
        handlers << name
      end
    end

  end
end
