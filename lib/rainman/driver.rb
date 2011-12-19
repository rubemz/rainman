module Rainman
  module Driver

    module Helpers
      def with_handler(handler, &block)
        h = self.class.handlers[handler].new
        yield h if block_given?
        h
      end
    end

    module DSL
      def self.extended(base)
        class << base
          attr_accessor :actions, :handlers, :default_handler
          attr_accessor :current_handler, :options
        end

        unless base.instance_variable_defined?(:@actions)
          base.instance_variable_set(:@actions,  [])
        end

        unless base.instance_variable_defined?(:@handlers)
          base.instance_variable_set(:@handlers, {})
        end

        unless base.instance_variable_defined?(:@options)
          base.instance_variable_set(:@options, {:global => Option.new(:global)})
        end
      end

      def included(base)
        base.instance_variable_set(:@actions,  actions)
        base.instance_variable_set(:@handlers, handlers)
        base.instance_variable_set(:@options,  options)
        base.send(:include, Helpers)
        base.extend(DSL)
      end

      def register_handler(name, &block)
        klass = "#{self.name}::#{name.to_s.camelize}".constantize
        klass.extend(Rainman::Handler)
        yield klass.config if block_given?

        handlers[name] = klass
      end

      def handler_exists?(name)
        handlers.has_key?(name)
      end

      def set_default_handler(name)
        @default_handler = handlers[name]
        set_current_handler(name) unless @current_handler
      end

      def set_current_handler(name)
        @current_handler = handlers[name].new
      end

      def add_option_all(opts = {})
        options[:global].add_option opts
      end

      def define_action(name, &block)
        options[name] ||= Option.new(name)
        actions << name

        yield options[name] if block_given?

        class_eval do
          define_method(name) do |*args|
            self.class.options[:global].validate!(*args)
            self.class.options[name].validate!(*args)

            if self.class.current_handler
              self.class.current_handler.send(name, *args)
            else
              raise "A default_handler has not been set"
            end
          end
        end
      end

      def define_namespace(name, &block)
      end
    end

    def self.extended(base)
      base.extend(DSL)
    end
  end
end
