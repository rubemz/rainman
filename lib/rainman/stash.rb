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
    #
    # Returns nothing.
    def initialize(params = {})
      @hash = params
    end

    # Public: Get the Hash of all variables.
    #
    # Returns a Hash.
    def to_hash
      @hash
    end

    # Internal: Used to allow lookup/assignment of variables from @hash.
    def method_missing(method, *args)
      if method.to_s[-1, 1] == '='
        super
      elsif args.size == 1 && args[0].nil?
        @hash.delete(method)
        nil
      elsif args.size > 0
        @hash[method] = args.size == 1 ? args[0] : args
      else
        @hash[method]
      end
    end
  end
end
