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
      actions << name

      yield options[name] if block_given?

      (class << self; self; end).class_eval do
        define_method name do |*args|
          options[:global].validate!(*args)
          options[name].validate!(*args)
        end
      end
    end

    def add_option_all(opts = {})
      options[:global].add_option opts
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
