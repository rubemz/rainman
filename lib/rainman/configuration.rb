module Rainman
  # The Configuration class stores a hash containing values that can be
  # used by drivers and handlers.
  class Configuration
    # Public: A Hash that stores all configurations.
    #
    # Returns a Hash.
    def self.global
      @global ||= {}
    end

    # Public: Initialize a new instance of this class, and sets a new namespace
    # on the global Hash.
    def initialize(name)
      @name = name
      self.class.global[name] = {}
    end

    # Public: Alias for the config data
    #
    # Returns a Hash.
    def global
      self.class.global
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
      if global[@name] && global[@name].has_key?(key)
        global[@name][key]
      elsif global[:global] && global[:global].has_key?(key)
        global[:global][key]
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
      global[@name][key] = value
    end
  end
end
