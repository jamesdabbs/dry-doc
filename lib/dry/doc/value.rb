class Dry::Doc::Value < ::Dry::Struct
  T = ::Dry::Types.module
  Types = ::Dry::Doc::Value::T::Strict

  module Types
    Inlines = Set.new

    def self.instance klass
      ::Dry::Doc::Value::T::Constructor klass
    end

    def self.constant value
      ::Dry::Doc::Value::T::Constant value
    end

    def self.sum left, right
      left  = instance left unless left.respond_to? :to_ast
      right = instance right unless right.respond_to? :to_ast
      ::Dry::Types::Sum.new left, right
    end

    def self.[] type
      ::Dry::Doc::Value::Types::Array.member type
    end

    def self.inline? klass
      ::Dry::Doc::Value::Types::Inlines.include? klass
    end
  end

  class << self
    def doc
      @_doc ||= ::Dry::Doc::Schema.new self
    end

    def types
      ::Dry::Doc::Value::Types
    end

    def as_open_api
      doc.as_json
    end

    def ref
      "#/definitions/#{@ref}" if @ref
    end

    def attribute name, type=nil, opts={}, &nested
      if nested
        opts = type || {}
        inline_class = build_type :"#{self.name}::#{name}", &nested
        ::Dry::Doc::Value::Types::Inlines.add inline_class
        type = types.instance inline_class
        type = type.optional if opts[:optional]
      end

      doc.register name, type, 
        description: opts.delete(:description)
      super name, type
    end

    def inspect
      "<#{name}>"
    end

    private

    def build_type name, &config
      Class.new ::Dry::Doc::Value do |klass|
        class_exec &config
        define_singleton_method(:name) { name }
      end
    end
  end

  def as_json *_
    to_h
  end
end