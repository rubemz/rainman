module Rainman
  module Driver
    def register_handler(name, &block)
      name  = name.to_s
      klass = "#{self.name}::#{name.to_s.camelize}"
      if self::const_defined?(name.camelize)
        k = klass.constantize.extend(Rainman::Handler)
        yield k.config if block_given?
      else
        raise "Unknown handler '#{self}::#{name.camelize}'"
      end
    end
  end
end
