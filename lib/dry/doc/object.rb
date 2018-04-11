class Dry::Doc::Object < ::Dry::Struct
  class << self
    attr_accessor :ref

    def doc
      @_doc ||= ::Dry::Doc::Schema.new self
    end

    def types
      ::Dry::Doc::Types
    end

    def as_open_api
      doc.as_json
    end

    def name
      ref
    end

    def attribute name, type=nil, opts={}, &nested
      if nested
        opts = type || {}
        inline_class = build_type :"#{self.name}::#{name}", &nested
        ::Dry::Doc.inline inline_class
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
      Class.new ::Dry::Doc::Object do |klass|
        class_exec &config
        define_singleton_method(:name) { name }
      end
    end
  end

  def as_json *_
    to_h
  end
end