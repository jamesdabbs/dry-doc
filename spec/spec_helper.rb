require 'bundler/setup'
require 'pry'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'dry/doc'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus

  config.disable_monkey_patching!

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed
end

module RSpec::Matchers
  define :define_components do
    match do |mod|
      api = {
       openapi: '3',
        info: {
          title: 'dry-doc',
          version: ::Dry::Doc::VERSION
        },
        paths: {},
        components: mod.as_open_api
      }

      f = Tempfile.new
      f.write JSON.dump api
      f.rewind
      begin
        # FIXME - Openapi3Parser doesn't seem to handle nested $refs
        #   so for now we're just shelling out to a python implementation
        @result = `openapi-spec-validator #{f.path} | head`.strip
        @result == 'OK'
      ensure
        f.unlink
      end
    end

    description do |mod|
      'define valid OpenAPI components'
    end

    failure_message do |mod|
      @result
    end
  end
end