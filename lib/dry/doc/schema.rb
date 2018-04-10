class Dry::Doc::Schema
  ::Dry::Doc::UnknownPrimitive = Class.new ::Dry::Doc::NotImplemented

  Nullable = :"x-nullable"
  T = ::Dry::Doc::Value::Types

  class Field < ::Dry::Struct
    attribute :type, Object
    attribute :description, T::String.optional

    def as_json
      ast = type.respond_to?(:to_ast) ? type.to_ast : type
      base = walk_ast(ast, {})
      base[:description] = description if description
      base
    end

    private

    BOOL_AST = ::Dry::Doc::Value::Types::Bool.to_ast[1][0 .. -2]

    def walk_ast ast, acc
      kind, data = ast

      # TODO: compare with 
      # https://github.com/dry-rb/dry-types/blob/d6e50bf54c42dd54ffc0e813738978f58bbfbfa7/lib/dry/types/compiler.rb
      # and see if we can clean this up and cover all the possibilities
      case kind
      when :array
        type, _meta = data
        acc[:type] = 'array'
        acc[:items] = walk_ast type, {}
        return acc

      when :constrained
        type, *constraints, _meta = data
        # FIXME: note `is?` constraints
        return walk_ast type, acc

      when :constructor
        definition, _cons, _meta = data
        return walk_ast definition, acc

      when :definition
        primitive, _meta = data

        if T.inline? primitive
          return acc.merge primitive.as_open_api
        elsif primitive.respond_to?(:ref) && primitive.ref
          return acc.merge ref: primitive.ref
        elsif primitive == Integer
          return acc.merge type: :integer
        elsif primitive == String
          return acc.merge type: :string
        elsif primitive == NilClass
          return acc.merge type: nil
        elsif primitive == DateTime
          return acc.merge type: :string, format: :'date-time'
        elsif primitive == Date
          return acc.merge type: :string, format: :date
        else
          # TODO: allow plugins for handling custom types
          # :nocov:
          raise ::Dry::Doc::UnknownPrimitive, primitive
          # :nocov:
        end

      when :sum
        *nodes, _meta = data

        if nodes == BOOL_AST
          return acc.merge type: :boolean
        end

        types = nodes.map { |i| walk_ast i, {} }
        nils, non_nils = types.partition { |t| t.key?(:type) && t[:type].nil? }
        if nils.length == 1 && non_nils.length == 1
          acc[:'x-nullable'] = true
          acc = acc.merge non_nils.first
        else
          acc = acc.merge oneOf: non_nils
        end
        return acc

      when :enum
        inner, _meta = data
        acc = walk_ast inner, acc
        acc[:values] = self.type.values # FIXME: this needs to look at the AST
        return acc
      end

      # :nocov:
      raise ::Dry::Doc::NotImplemented, "AST kind: #{kind} | #{data}"
      # :nocov:
    end
  end

  attr_reader :klass

  def initialize klass
    @klass, @properties = klass, {}
  end

  def register name, type, description:
    @properties[name] = Field.new \
      type:        type,
      description: description
  end

  def as_json
    { 
      type: :object,
      properties: @properties.transform_values(&:as_json)
    }
  end
end