module Dry::Doc
  class Type
    attr_accessor :ref

    def initialize inner
      @inner = inner
    end

    def call *args
      @inner.call *args
    end

    def as_open_api
      # TODO: this smells
      ::Dry::Doc::Schema::Field.new(
        type: @inner,
        description: nil
      ).as_json
    end

    def name
      ref
    end

    def to_ast *args
      @inner.to_ast *args
    end

    def inspect
      "<#{name}>"
    end
  end

  module Namespace
    def definitions
      @_definitions ||= []
    end

    def define name, &config
      klass = Class.new ::Dry::Doc::Object do |c|
        class_exec &config
      end
      register name, klass 
    end

    def type name, inner
      klass = ::Dry::Doc::Type.new inner
      register name, klass
    end

    def types
      ::Dry::Doc::Types
    end

    def as_open_api
      definitions.freeze

      defs = definitions.each_with_object({}) do |d, h|
        h[d.name] = d.as_open_api
      end

      { 
        schemas: defs
      }
    end

    private

    def register name, klass
      klass.ref = name
      klass.freeze

      const_set name, klass
      definitions.push klass
      klass
    end
  end
end