class Dry::Doc::Value < ::Dry::Struct
  module Types
    include ::Dry::Types.module
  end

  def self.doc
    @_doc ||= ::Dry::Doc::Schema.new self
  end

  def self.types
    ::Dry::Doc::Value::Types::Strict
  end

  def self.as_open_api
    doc.as_json
  end

  def self.attribute name, type, opts={}
    doc.register name, type, 
      description: opts.delete(:description)
    super name, type
  end

  def as_json
    to_h
  end
end