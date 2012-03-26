# This file contains a few methods from ActiveSupport that are used by
# Rainman. If ActiveSupport has been loaded, those methods will be used rather
# than those in this file.

# From activesupport/lib/active_support/inflector/methods.rb
class String
  # Public: Convert a string into a constant. The constant must exist in
  # ObjectSpace.
  #
  # Raises NameError if the constant does not exist.
  #
  # Returns a constant.
  def constantize
    names = split('::')
    names.shift if names.empty? || names.first.empty?

    constant = Object
    names.each do |name|
      constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
    end
    constant
  end unless respond_to?(:constantize)

  # Public: Camel-case a string.
  #
  # Examples
  #
  #   "foo_bar"     #=> "FooBar"
  #   "foo_bar/baz" #=> "FooBar::Baz"
  #
  # Returns a String.
  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      self[0].chr.downcase + camelize(self)[1..-1]
    end
  end unless respond_to?(:camelize)

  # Makes an underscored, lowercase form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  # Examples:
  #   "ActiveModel".underscore         # => "active_model"
  #   "ActiveModel::Errors".underscore # => "active_model/errors"
  #
  # As a rule of thumb you can think of +underscore+ as the inverse of +camelize+,
  # though there are cases where that does not hold:
  #
  #   "SSLError".underscore.camelize # => "SslError"
  def underscore
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end unless respond_to?(:underscore)
end

# From lib/active_support/core_ext/hash/reverse_merge.rb
class Hash
  # Public: Reverse merge a hash.
  #
  # Example
  #
  #   a = { :one => :A }
  #   b = a.reverse_merge(:one => :B, :two => :two)
  #   a #=> { :one => :A }
  #   b #=> { :one => :A, :two => :two }
  #
  # Returns a new Hash.
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end unless respond_to?(:reverse_merge)

  # Public: Reverse merge a hash in-place.
  #
  # Example
  #
  #   a = { :one => :A }
  #   a.reverse_merge!(:one => :B, :two => :two)
  #   a #=> { :one => :A, :two => :two }
  #
  # Returns a Hash.
  def reverse_merge!(other_hash)
    # right wins if there is no left
    merge!( other_hash ){|key,left,right| left }
  end unless respond_to?(:reverse_merge!)

  if respond_to?(:reverse_merge!) && ! respond_to?(:reverse_update)
    # Alias Hash#reverse_update
    alias_method :reverse_update, :reverse_merge!
  end
end
