# Dry::Doc

```
module MyApi
  extend Dry::Doc::Namespace

  define :User do
    # dry-struct definitions
    attribute :name, types::String
    attribute :age, types::Int.optional
  end

  define :Post do
    attribute :author, types.instance(User)
    attribute :title, types::String
    attribute :body, types::String
    attribute :created_at, types::DateTime
  end
end
```

Get serializable objects that check their input

```
u = MyApi::User.new(name: 'James', age: nil)
u.as_json
# => { name: "James", age: nil}

v = MyApi::User.new(name: 0, age: '')
# => Dry::Struct::Error: [MyApi::User.new] :name is missing in Hash input

p = MyApi::Post.new(author: u, title: '...', body: '...', created_at: DateTime.now).as_json
# => { author: { name: "James", age: null }, title: "...", body: "...", created_at: "..." }

```

and provide an open api definition (with e.g. `JSON.pretty_generate MyApi.as_open_api`)

```
{
  "definitions": {
    "User": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        },
        "age": {
          "nullable": true,
          "type": "integer"
        }
      }
    },
    "Post": {
      "type": "object",
      "properties": {
        "author": {
          "ref": "#/definitions/User"
        },
        "title": {
          "type": "string"
        },
        "body": {
          "type": "string"
        },
        "created_at": {
          "type": "string",
          "format": "date-time"
        }
      }
    }
  }
}
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-doc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-doc

## Usage

See the specs for further examples. This currently implements just enough to get by, but the eventual hope is to be fully compatible with the OpenAPI spec.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jamesdabbs/dry-doc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

