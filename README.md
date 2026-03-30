# philiprehberger-test_factory

[![Tests](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-test_factory.svg)](https://rubygems.org/gems/philiprehberger-test_factory)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-test-factory)](https://github.com/philiprehberger/rb-test-factory/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-test-factory)](https://github.com/philiprehberger/rb-test-factory/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-test-factory)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-test-factory/bug)](https://github.com/philiprehberger/rb-test-factory/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-test-factory/enhancement)](https://github.com/philiprehberger/rb-test-factory/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

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

### Callbacks

```ruby
Philiprehberger::TestFactory.define(:user) do |f|
  f.after_build { |obj| obj[:created_at] = Time.now }
  { name: "Alice", email: "alice@example.com" }
end
```

### Transient Attributes

```ruby
Philiprehberger::TestFactory.define(:user) do |f|
  f.transient { admin false }
  f.after_build { |obj, transients| obj[:role] = "admin" if transients[:admin] }
  { name: "Alice", role: "user" }
end

user = Philiprehberger::TestFactory.build(:user, admin: true)
# => { name: "Alice", role: "admin" }
```

### Associations

```ruby
Philiprehberger::TestFactory.define(:user) { { name: "Alice" } }
Philiprehberger::TestFactory.define(:post) do |f|
  f.association :author, factory: :user
  { title: "Hello World" }
end

post = Philiprehberger::TestFactory.build(:post)
# => { title: "Hello World", author: { name: "Alice" } }
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
| `DefinitionProxy#after_build(&block)` | Register a callback that runs after building |
| `DefinitionProxy#transient(&block)` | Declare transient attributes excluded from the result |
| `DefinitionProxy#association(name, factory:)` | Declare an association to another factory |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
