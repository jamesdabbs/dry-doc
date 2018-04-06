require "spec_helper"

class A < ::Dry::Doc::Value
  attribute :foo, types::Int,
    description: 'An integer field'
  attribute :bar, types::Int.optional,
    description: 'An integer field that might be null'
  attribute :baz, types::String.enum('a', 'b', 'c'),
    description: 'An enum of strings'
end

RSpec.describe Dry::Doc do
  it 'can produce an open-api doc' do
    expect(A.as_open_api).to eq \
      type: :object,
      properties: {
        foo: {
          type: :integer,
          description: 'An integer field'
        },
        bar: {
          type: :integer,
          description: 'An integer field that might be null',
          "x-nullable": true
        },
        baz: {
          type: :string,
          description: 'An enum of strings',
          values: ['a', 'b', 'c']
        }
      }
  end

  it 'can serialize an object' do
    a = A.new(foo: 1, bar: nil, baz: 'b')
    expect(a.as_json).to eq(foo: 1, bar: nil, baz: 'b')
  end

  it 'type-checks objects' do
    expect do
      A.new(foo: 2, bar: nil, baz: 'z')
    end.to raise_error(/baz/)

    expect do
      A.new(foo: nil, bar: 3, baz: 'c')
    end.to raise_error(/foo/)
  end
end
