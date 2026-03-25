# philiprehberger-test_factory

[![Tests](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-test_factory.svg)](https://rubygems.org/gems/philiprehberger-test_factory)
[![License](https://img.shields.io/github/license/philiprehberger/rb-test-factory)](LICENSE)

Lightweight test data factory DSL with sequences and traits

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-test_factory"
```

Or install directly:

```bash
gem install philiprehberger-test_factory
```

## Usage

```ruby
require "philiprehberger/test_factory"

# Define a factory
Philiprehberger::TestFactory.define(:user) do
  { name: "Alice", email: "alice@example.com", role: "user" }
end

# Build a single object
user = Philiprehberger::TestFactory.build(:user)
# => { name: "Alice", email: "alice@example.com", role: "user" }

# Build with overrides
admin = Philiprehberger::TestFactory.build(:user, role: "admin")
# => { name: "Alice", email: "alice@example.com", role: "admin" }
```

### Traits

```ruby
Philiprehberger::TestFactory.trait(:user, :admin) { { role: "admin" } }
Philiprehberger::TestFactory.trait(:user, :inactive) { { active: false } }

admin = Philiprehberger::TestFactory.build(:user, traits: [:admin])
# => { name: "Alice", email: "alice@example.com", role: "admin" }
```

### Sequences

```ruby
Philiprehberger::TestFactory.sequence(:email) { |n| "user_#{n}@example.com" }

# Access via the registry
email = Philiprehberger::TestFactory.send(:registry).next_in_sequence(:email)
# => "user_1@example.com"
```

### Build Lists

```ruby
users = Philiprehberger::TestFactory.build_list(:user, 5)
# => Array of 5 user hashes
```

### Reset

```ruby
Philiprehberger::TestFactory.reset!
```

## API

| Method | Description |
|--------|-------------|
| `TestFactory.define(name, &block)` | Register a factory; block returns a hash of defaults |
| `TestFactory.trait(factory_name, trait_name, &block)` | Register a trait override for a factory |
| `TestFactory.sequence(name, &block)` | Register a thread-safe auto-incrementing sequence |
| `TestFactory.build(name, traits:, **overrides)` | Build a single data hash |
| `TestFactory.build_list(name, count, traits:, **overrides)` | Build N data hashes |
| `TestFactory.reset!` | Clear all definitions, traits, and sequences |
| `Registry#define(name, &block)` | Store a factory definition |
| `Registry#trait(factory_name, trait_name, &block)` | Store a trait override |
| `Registry#sequence(name, &block)` | Store a sequence generator |
| `Registry#get(name)` | Retrieve a factory definition |
| `Registry#get_trait(factory_name, trait_name)` | Retrieve a trait |
| `Registry#next_in_sequence(name)` | Get next value from a sequence |
| `Registry#clear!` | Reset all definitions |
| `Builder#build(name, traits:, **overrides)` | Build one hash from factory + traits + overrides |
| `Builder#build_list(name, count, traits:, **overrides)` | Build N hashes |
| `Sequence#next` | Increment counter and return block result (thread-safe) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
