module Rainman
  # The Configuration class stores a hash containing values that can be
  # used by drivers and handlers.
  class Configuration
    # Public: A Hash that stores all configurations.
    #
    # Returns a Hash.
    def self.data
      @data ||= {}
    end

    # Public: Initialize a new instance of this class, and sets a new namespace
    # on the data Hash.
    def initialize(name)
      @name = name
      self.class.data[name] = { :validations => {} }
    end

    # Public: Alias for the config data
    #
    # Returns a Hash.
    def data
      self.class.data
    end

    # Public: Lookup a key
    #
    # If it doesn't exist in the current namespace, check for it in global
    # instead.
    #
    # Example
    #
    #   config[:blah]
    #
    # Returns the value or nil.
    def [](key)
      if data[@name] && data[@name].has_key?(key)
        data[@name][key]
      elsif data[:global] && data[:global].has_key?(key)
        data[:global][key]
      end
    end

    # Public> Set a key on the current namespace.
    #
    # Example
    #
    #   config[:blah] = :one
    #
    # Returns the value being set.
    def []=(key, value)
      data[@name][key] = value
    end
  end
end
