module Dry::Doc
  module Namespace
    def definitions
      @_definitions ||= []
    end

    def define name, &config
      klass = Class.new ::Dry::Doc::Value do |c|
        @ref = name
        class_exec &config
      end
      klass.define_singleton_method(:name) { name }

      const_set name, klass 
      definitions.push klass
      klass
    end

    def types
      ::Dry::Doc::Value::Types
    end

    def as_open_api
      definitions.freeze

      defs = definitions.each_with_object({}) do |d, h|
        h[d.name] = d.as_open_api
      end

      { 
        definitions: defs
      }
    end
  end
end