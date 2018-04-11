require 'dry-struct'

require 'dry/doc/version'

module Dry
  module Doc
    NotImplemented = Class.new ::NotImplementedError

    T = ::Dry::Types.module
    Types = ::Dry::Doc::T::Strict

    module Types
      def self.instance klass
        ::Dry::Doc::T::Constructor klass
      end

      def self.constant value
        ::Dry::Doc::T::Constant value
      end

      def self.sum left, right
        left  = instance left unless left.respond_to? :to_ast
        right = instance right unless right.respond_to? :to_ast
        ::Dry::Types::Sum.new left, right
      end

      def self.[] type
        ::Dry::Doc::Types::Array.member type
      end
    end

    Inlines = Set.new
    def self.inline klass
      Inlines.add klass
    end
    def self.inline? klass
      Inlines.include? klass
    end
  end
end

require 'dry/doc/object'
require 'dry/doc/schema'
require 'dry/doc/namespace'

