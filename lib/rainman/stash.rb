module Rainman
  # A Rainman Stash is used to store configuration variables, validations,
  # etc. It is similar to an OpenStruct, but allows assignment without using
  # `=`.
  #
  # Examples
  #
  #   stash = Stash.new
  #
  # Sets username to `:user`:
  #
  #   stash.username :user
  #
  # Gets username:
  #
  #   stash.username #=> :user
  #
  # Clear username:
  #
  #   stash.username nil #=> nil
  #   stash.username     #=> nil
  class Stash
    # Internal: Initializes a new Stash object.
    #
    # params - A Hash of parameters to set.
    def initialize(params = {})
      @hash = params
    end

    # Public: Get the Hash of all variables.
    #
    # Returns a Hash.
    def to_hash
      @hash
    end

    # Public: Retrieve value from @hash.
    #
    # key - The Symbol key to lookup in @hash.
    #
    # Examples
    #
    #   stash = Stash.new(name: "ABC")
    #   stash[:name] #=> 'ABC'
    #
    # Returns the value.
    def [](key)
      @hash[key]
    end

    # Public: Sets value on @hash.
    #
    # key    - The Symbol key to add to @hash.
    # values - One or more values to assign.
    #
    # Examples
    #
    #   stash = Stash.new
    #   stash[:name] = 'ABC Guy'
    #   stash.name #=> 'ABC Guy'
    #
    #   stash[:initials] = 'A', 'G'
    #   stash.initials #=> ['A', 'G']
    #
    #   stash[:name] = nil
    #   stash.name #=> nil
    #
    # Returns the value being set or nil if the value was cleared.
    def []=(key, values)
      values = Array.wrap(values)

      if values.size == 1 && values[0].nil?
        @hash.delete(key)
        nil
      else
        @hash[key] = values.size == 1 ? values[0] : values
      end
    end

    # Internal: Used to allow lookup/assignment of variables from @hash.
    #
    # method - The missing method name.
    # args   - Arguments to be supplied to the method (optional).
    #
    # Raises NameError if trying to assign with `=`, (eg: stash.name = :foo).
    #
    # Returns the value being set/retrieved.
    def method_missing(method, *args)
      if method.to_s[-1, 1] == '='
        super
      elsif args.size > 0
        self[method] = args
      end

      self[method]
    end
  end
end
