module Rainman
  module Driver

    module DSL
      def self.extended(base)
        class << base
          attr_accessor :actions, :handlers, :default_handler, :current_handler
        end

        unless base.instance_variable_defined?(:@actions)
          base.instance_variable_set(:@actions,  [])
        end

        unless base.instance_variable_defined?(:@handlers)
          base.instance_variable_set(:@handlers, {})
        end
      end

      def included(base)
        base.instance_variable_set(:@actions,  actions)
        base.instance_variable_set(:@handlers, handlers)
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

      def define_action(name, &block)
        actions << name

        class_eval do
          define_method(name) do |*args|
            if self.class.current_handler
              self.class.current_handler.send(name, *args)
            else
              raise "no handler silly"
            end
          end
        end
      end
    end

    def self.extended(base)
      base.extend(DSL)
    end
  end
end
