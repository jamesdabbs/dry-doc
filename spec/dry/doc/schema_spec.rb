require 'spec_helper'

m = Module.new do |m|
  extend ::Dry::Doc::Namespace

  define :A do
    attribute :foo, types::Int
  end

  define :B do
    attribute :single, types.instance(m::A)
    attribute :list, types[types.instance m::A] 
  end

  define :PrimitiveTypes do
    attribute :date, types::Date
    attribute :datetime, types::DateTime
    attribute :bool, types::Bool
    attribute :five, types.constant(5)
  end

  define :OptionalInline do
    attribute :nested, optional: true do
      attribute :name, types::String
    end
  end

  define :Sum do
    attribute :basic, types::String | types::Int
    attribute :compound, types.sum(m::A, m::B)
  end

  type :Letters, types::String.enum('a', 'b', 'c')
  define :WithLetter do
    attribute :letter, m::Letters
  end
end

RSpec.describe Dry::Doc::Schema do
  it "produces a valid document" do
    expect(m).to define_components
  end

  context 'references' do
    it 'produces schema for references and lists' do
      expect(m::B.as_open_api).to eq \
        type: :object,
        properties: {
          single: {
            '$ref': '#/components/schemas/A'
          },
          list: {
            type: 'array',
            items: {
              '$ref': '#/components/schemas/A'
            }
          }
        }
    end

    it 'can instantiate objects with references' do
      b = m::B.new \
        single: m::A.new(foo: 1),
        list: [m::A.new(foo: 2), m::A.new(foo: 3)]
      expect(b.list.map &:foo).to eq [2,3]
    end

    it 'can instantiate objects with nested structs' do
      b = m::B.new \
        single: { foo: 1 },
        list: [ { foo: 2 }, { foo: 3 }]
      expect(b.list.map &:foo).to eq [2,3]
    end

    it 'validates nested structs' do
      expect do
        b = m::B.new \
          single: { foo: 1 },
          list: [ { bar: 1 } ]
      end.to raise_error /foo/
    end
  end

  context 'nesting' do
    class C < ::Dry::Doc::Object
      attribute :name, types::String, description: 'Outer name'
      attribute(:nested,
        description: 'An inline nested attribute'
      ) do
        attribute :name, types::String, description: 'Inner name'
      end
    end

    it 'produces schema for inline nested objects' do
      expect(C.as_open_api).to eq \
        type: :object,
        properties: {
          name: {
            type: :string,
            description: 'Outer name'
          },
          nested: {
            type: :object,
            description: 'An inline nested attribute',
            properties: {
              name: {
                type: :string,
                description: 'Inner name'
              }
            }
          }
        }
    end

    it 'can instantiate nested objects' do
      c = C.new(
        name: 'outer',
        nested: {
          name: 'inner'
        }
      )
      expect(c.name).to eq 'outer'
      expect(c.nested.name).to eq 'inner'
    end
  end

  context 'primitives' do
    it 'renders primitive types' do
      expect(m::PrimitiveTypes.as_open_api).to eq \
        type: :object,
        properties: {
          date: {
            type: :string,
            format: :date
          },
          datetime: {
            type: :string,
            format: :'date-time'
          },
          bool: {
            type: :boolean
          },
          five: {
            type: :integer,
            enum: [5]
          }
        }
    end
  end

  context 'optional inline' do 
    it 'can generate docs' do
      expect(m::OptionalInline.as_open_api).to eq \
        type: :object,
        properties: {
          nested: {
            type: :object,
            nullable: true,
            properties: {
              name: {
                type: :string
              }
            }
          }
        }
    end

    it 'can instantiate with the inline type' do
      oi = m::OptionalInline.new(nested: { name: 'oi' })
      expect(oi.nested.name).to eq 'oi'
    end

    it 'can instantiate with nil' do
      oi = m::OptionalInline.new(nested: nil)
      expect(oi.nested).to eq nil
    end
  end

  context 'sum' do
    it 'can render a sum type' do
      expect(m::Sum.as_open_api).to eq \
        type: :object,
        properties: {
          basic: {
            oneOf: [
              { type: :string },
              { type: :integer }
            ]
          },
          compound: {
            oneOf: [
              { '$ref': '#/components/schemas/A' },
              { '$ref': '#/components/schemas/B' }
            ]
          }
        }
    end
  end

  context 'defined type enums' do
    it 'generates documentation' do
      expect(m::Letters.as_open_api).to eq \
        type: :string,
        enum: %w(a b c)

      expect(m::WithLetter.as_open_api).to eq \
        type: :object,
        properties: {
          letter: {
            # TODO: should this be a ref?
            type: :string,
            enum: %w(a b c)
          }
        }
    end

    it 'can be instantiated' do
      expect(m::WithLetter.new(letter: 'b').as_json).to eq(letter: 'b')
    end
  end
end