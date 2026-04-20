# philiprehberger-test_factory

[![Tests](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-test-factory/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-test_factory.svg)](https://rubygems.org/gems/philiprehberger-test_factory)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-test-factory)](https://github.com/philiprehberger/rb-test-factory/commits/main)

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

### Collections

Generate N objects at once with `build_list`. Each element goes through the
normal `build` path, so sequences increment once per object and overrides or
traits apply identically to every element.

```ruby
Philiprehberger::TestFactory.sequence(:email) { |n| "user_#{n}@example.com" }
Philiprehberger::TestFactory.define(:user) do
  {
    name: "User",
    email: Philiprehberger::TestFactory.send(:registry).next_in_sequence(:email),
    role: "user"
  }
end

users = Philiprehberger::TestFactory.build_list(:user, 3)
# => [
#      { name: "User", email: "user_1@example.com", role: "user" },
#      { name: "User", email: "user_2@example.com", role: "user" },
#      { name: "User", email: "user_3@example.com", role: "user" }
#    ]

# Apply overrides and traits to every element
Philiprehberger::TestFactory.trait(:user, :admin) { { role: "admin" } }

admins = Philiprehberger::TestFactory.build_list(:user, 2, traits: [:admin], name: "Bob")
# => [
#      { name: "Bob", email: "user_4@example.com", role: "admin" },
#      { name: "Bob", email: "user_5@example.com", role: "admin" }
#    ]

# count == 0 returns an empty array
Philiprehberger::TestFactory.build_list(:user, 0)
# => []

# Negative counts raise ArgumentError
Philiprehberger::TestFactory.build_list(:user, -1)
# => ArgumentError: count must be non-negative, got -1
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

### Attributes For

Return a plain attribute hash without firing `after_build` callbacks or
resolving `association` objects — useful for unit tests that need the raw
attributes without nested dependencies. Mirrors FactoryBot's `attributes_for`.

```ruby
Philiprehberger::TestFactory.define(:user) do
  { name: "Alice", role: "user" }
end

attrs = Philiprehberger::TestFactory.attributes_for(:user, role: :admin)
# => { name: "Alice", role: :admin }
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
| `TestFactory.build_pair(name, traits:, **overrides)` | Build exactly 2 data hashes (FactoryBot-compatible convenience) |
| `TestFactory.attributes_for(name, traits:, **overrides)` | Resolve attributes without `after_build` callbacks or associations |
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

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-test-factory)

🐛 [Report issues](https://github.com/philiprehberger/rb-test-factory/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-test-factory/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
