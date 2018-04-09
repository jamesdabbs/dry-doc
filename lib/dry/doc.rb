require 'dry-struct'

require 'dry/doc/version'

module Dry
  module Doc
    NotImplemented = Class.new ::NotImplementedError
  end
end

require 'dry/doc/value'
require 'dry/doc/schema'
require 'dry/doc/namespace'

