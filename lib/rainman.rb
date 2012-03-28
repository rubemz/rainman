require "rainman/version"

begin
  require "active_support/core_ext/string"
  require "active_support/core_ext/hash"
rescue LoadError
  require "rainman/support"
end

require "rainman/exceptions"
require "rainman/runner"
require "rainman/driver"

module Rainman
end
