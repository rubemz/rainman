module Rainman
  class Option
    attr_reader :name
    attr_reader :all

    # The name of the option
    def initialize(name)
      @name = name
      @all  = {}
    end

    # Add an option
    def add_option(opts = {})
      return if opts.blank?

      if opts.is_a?(Hash)
        all.merge!(opts)
      else
        all.merge!(opts => true)
      end
    end

    # Return required args
    def required
      all.collect { |k,v| k if all[k][:required] }
    end

    # Validate options. Raises on error
    def validate!(opts = {})
      if opts.is_a?(Hash)
        required.each { |k,v| raise ":#{k} is required" unless opts.include?(k) }
      else
        raise "opts must be a hash"
      end
    end

  end
end
