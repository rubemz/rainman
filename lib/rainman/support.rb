# From activesupport/lib/active_support/inflector/methods.rb
class String
  unless respond_to?(:constantize)
    def constantize
      names = split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end

  unless respond_to?(:camelize)
    def camelize(first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        self[0].chr.downcase + camelize(self)[1..-1]
      end
    end
  end
end

# From lib/active_support/core_ext/hash/reverse_merge.rb
class Hash
  unless respond_to?(:reverse_merge)
    def reverse_merge(other_hash)
      other_hash.merge(self)
    end
  end

  unless respond_to?(:reverse_merge!)
    def reverse_merge!(other_hash)
      # right wins if there is no left
      merge!( other_hash ){|key,left,right| left }
    end
  end

  if respond_to?(:reverse_merge!) && ! respond_to?(:reverse_update)
    alias_method :reverse_update, :reverse_merge!
  end
end
