class Dry::Doc::Schema
  Nullable = :"x-nullable"
  T = ::Dry::Doc::Value::Types

  class Field < ::Dry::Struct
    attribute :type, Object
    attribute :description, T::String.optional

    def as_json
      {
        type:         api_type,
        description:  description,
      }.tap do |j|
        if type.optional?
          j[Nullable] = true
        end
        if type.respond_to? :values
          j[:values] = type.values
        end
      end
    end

    private

    def api_type
      if primitive == Integer
        :integer
      elsif primitive == String
        :string
      else
        raise NotImplementedError
      end
    end

    def primitive
      t = type.optional? ? type.right : type
      t&.primitive
    end
  end

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