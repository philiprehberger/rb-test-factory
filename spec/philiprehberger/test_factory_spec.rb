# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TestFactory do
  before { described_class.reset! }

  it 'has a version number' do
    expect(Philiprehberger::TestFactory::VERSION).not_to be_nil
  end

  describe '.define and .build' do
    it 'defines and builds a simple factory' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }

      result = described_class.build(:user)

      expect(result).to eq(name: 'Alice', email: 'alice@example.com')
    end

    it 'builds with overrides' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }

      result = described_class.build(:user, name: 'Bob')

      expect(result).to eq(name: 'Bob', email: 'alice@example.com')
    end

    it 'builds an empty factory' do
      described_class.define(:empty) { {} }

      result = described_class.build(:empty)

      expect(result).to eq({})
    end

    it 'builds with no overrides' do
      described_class.define(:post) { { title: 'Hello' } }

      result = described_class.build(:post)

      expect(result).to eq(title: 'Hello')
    end

    it 'allows overriding all attributes' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }

      result = described_class.build(:user, name: 'Bob', email: 'bob@example.com')

      expect(result).to eq(name: 'Bob', email: 'bob@example.com')
    end

    it 'allows adding attributes not in the factory definition' do
      described_class.define(:user) { { name: 'Alice' } }

      result = described_class.build(:user, age: 30)

      expect(result).to eq(name: 'Alice', age: 30)
    end

    it 'supports factories with many attributes' do
      described_class.define(:profile) do
        {
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          role: 'user',
          active: true,
          score: 100
        }
      end

      result = described_class.build(:profile)

      expect(result.keys.size).to eq(6)
    end

    it 'calls the factory block each time to get fresh defaults' do
      call_count = 0
      described_class.define(:counter) do
        call_count += 1
        { count: call_count }
      end

      r1 = described_class.build(:counter)
      r2 = described_class.build(:counter)

      expect(r1[:count]).to eq(1)
      expect(r2[:count]).to eq(2)
    end

    it 'redefines a factory when called again with the same name' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:user) { { name: 'Bob' } }

      result = described_class.build(:user)

      expect(result).to eq(name: 'Bob')
    end
  end

  describe '.build_list' do
    it 'returns the correct number of items' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_list(:user, 3)

      expect(results.size).to eq(3)
      expect(results).to all(eq(name: 'Alice'))
    end

    it 'returns an empty array when count is zero' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_list(:user, 0)

      expect(results).to eq([])
    end

    it 'applies overrides to each item in the list' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }

      results = described_class.build_list(:user, 3, role: 'admin')

      expect(results).to all(include(role: 'admin'))
    end

    it 'applies traits to each item in the list' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      results = described_class.build_list(:user, 2, traits: [:admin])

      expect(results).to all(include(role: 'admin'))
    end

    it 'calls factory block independently for each item' do
      counter = 0
      described_class.define(:item) do
        counter += 1
        { id: counter }
      end

      results = described_class.build_list(:item, 3)

      expect(results.map { |r| r[:id] }).to eq([1, 2, 3])
    end

    it 'raises an error for undefined factory' do
      expect { described_class.build_list(:nonexistent, 2) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end
  end

  describe '.trait' do
    it 'overrides specific fields with a trait' do
      described_class.define(:user) { { name: 'Alice', role: 'user', active: true } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      result = described_class.build(:user, traits: [:admin])

      expect(result).to eq(name: 'Alice', role: 'admin', active: true)
    end

    it 'applies multiple traits in order' do
      described_class.define(:user) { { name: 'Alice', role: 'user', active: true } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.trait(:user, :inactive) { { active: false } }

      result = described_class.build(:user, traits: %i[admin inactive])

      expect(result).to eq(name: 'Alice', role: 'admin', active: false)
    end

    it 'raises an error for undefined traits' do
      described_class.define(:user) { { name: 'Alice' } }

      expect { described_class.build(:user, traits: [:unknown]) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Trait :unknown/)
    end

    it 'last trait wins when traits conflict' do
      described_class.define(:user) { { role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.trait(:user, :superadmin) { { role: 'superadmin' } }

      result = described_class.build(:user, traits: %i[admin superadmin])

      expect(result[:role]).to eq('superadmin')
    end

    it 'overrides take precedence over traits' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      result = described_class.build(:user, traits: [:admin], role: 'superadmin')

      expect(result[:role]).to eq('superadmin')
    end

    it 'supports traits that add new attributes' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.trait(:user, :with_email) { { email: 'alice@example.com' } }

      result = described_class.build(:user, traits: [:with_email])

      expect(result).to eq(name: 'Alice', email: 'alice@example.com')
    end

    it 'supports an empty traits array' do
      described_class.define(:user) { { name: 'Alice' } }

      result = described_class.build(:user, traits: [])

      expect(result).to eq(name: 'Alice')
    end
  end

  describe '.sequence' do
    it 'auto-increments values' do
      described_class.sequence(:counter) { |n| n }

      results = Array.new(3) { described_class.send(:registry).next_in_sequence(:counter) }

      expect(results).to eq([1, 2, 3])
    end

    it 'is thread-safe' do
      described_class.sequence(:thread_seq) { |n| n }

      results = []
      mutex = Mutex.new
      threads = Array.new(10) do
        Thread.new do
          20.times do
            val = described_class.send(:registry).next_in_sequence(:thread_seq)
            mutex.synchronize { results << val }
          end
        end
      end
      threads.each(&:join)

      expect(results.sort).to eq((1..200).to_a)
    end

    it 'supports string sequences' do
      described_class.sequence(:email) { |n| "user_#{n}@example.com" }

      val = described_class.send(:registry).next_in_sequence(:email)

      expect(val).to eq('user_1@example.com')
    end

    it 'raises for undefined sequence' do
      expect { described_class.send(:registry).next_in_sequence(:missing) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Sequence :missing is not defined/)
    end

    it 'maintains independent counters per sequence' do
      described_class.sequence(:seq_a) { |n| "a_#{n}" }
      described_class.sequence(:seq_b) { |n| "b_#{n}" }

      a1 = described_class.send(:registry).next_in_sequence(:seq_a)
      b1 = described_class.send(:registry).next_in_sequence(:seq_b)
      a2 = described_class.send(:registry).next_in_sequence(:seq_a)

      expect(a1).to eq('a_1')
      expect(b1).to eq('b_1')
      expect(a2).to eq('a_2')
    end
  end

  describe '.reset!' do
    it 'clears all definitions' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.reset!

      expect { described_class.build(:user) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :user is not defined/)
    end

    it 'clears all traits' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.reset!
      described_class.define(:user) { { name: 'Alice' } }

      expect { described_class.build(:user, traits: [:admin]) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Trait :admin/)
    end

    it 'clears all sequences' do
      described_class.sequence(:counter) { |n| n }
      described_class.reset!

      expect { described_class.send(:registry).next_in_sequence(:counter) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Sequence :counter is not defined/)
    end
  end

  describe 'error handling' do
    it 'raises an error for undefined factories' do
      expect { described_class.build(:nonexistent) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end

    it 'error class inherits from StandardError' do
      expect(Philiprehberger::TestFactory::Error.ancestors).to include(StandardError)
    end

    it 'includes the factory name in the error message' do
      expect { described_class.build(:widget) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Factory :widget is not defined')
    end

    it 'raises for trait on undefined factory' do
      expect { described_class.build(:nonexistent, traits: [:admin]) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end
  end

  describe '.define and .build (edge cases)' do
    it 'supports overriding a value with nil' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }

      result = described_class.build(:user, email: nil)

      expect(result).to eq(name: 'Alice', email: nil)
    end

    it 'supports nested hash values' do
      described_class.define(:config) do
        { database: { host: 'localhost', port: 5432 }, debug: false }
      end

      result = described_class.build(:config)

      expect(result[:database]).to eq(host: 'localhost', port: 5432)
      expect(result[:debug]).to eq(false)
    end

    it 'overrides nested hash entirely rather than deep-merging' do
      described_class.define(:config) do
        { database: { host: 'localhost', port: 5432 } }
      end

      result = described_class.build(:config, database: { host: 'remote' })

      expect(result[:database]).to eq(host: 'remote')
    end

    it 'supports string keys in factory hashes' do
      described_class.define(:data) { { 'key' => 'value', 'count' => 1 } }

      result = described_class.build(:data)

      expect(result).to eq('key' => 'value', 'count' => 1)
    end

    it 'supports factories with array values' do
      described_class.define(:post) { { title: 'Hello', tags: %w[ruby test] } }

      result = described_class.build(:post)

      expect(result[:tags]).to eq(%w[ruby test])
    end

    it 'supports multiple independent factories' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) { { title: 'Hello' } }
      described_class.define(:comment) { { body: 'Great!' } }

      expect(described_class.build(:user)).to eq(name: 'Alice')
      expect(described_class.build(:post)).to eq(title: 'Hello')
      expect(described_class.build(:comment)).to eq(body: 'Great!')
    end

    it 'supports boolean false as a default value' do
      described_class.define(:feature) { { enabled: false, name: 'dark_mode' } }

      result = described_class.build(:feature)

      expect(result[:enabled]).to eq(false)
    end
  end

  describe '.trait (edge cases)' do
    it 'applies a trait that returns an empty hash' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :noop) { {} }

      result = described_class.build(:user, traits: [:noop])

      expect(result).to eq(name: 'Alice', role: 'user')
    end

    it 'allows redefining a trait' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.trait(:user, :admin) { { role: 'superadmin' } }

      result = described_class.build(:user, traits: [:admin])

      expect(result[:role]).to eq('superadmin')
    end

    it 'supports traits on different factories independently' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.define(:post) { { title: 'Hello', status: 'draft' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.trait(:post, :published) { { status: 'published' } }

      user = described_class.build(:user, traits: [:admin])
      post = described_class.build(:post, traits: [:published])

      expect(user[:role]).to eq('admin')
      expect(post[:status]).to eq('published')
    end

    it 'raises with correct message for undefined trait including factory name' do
      described_class.define(:post) { { title: 'Hello' } }

      expect { described_class.build(:post, traits: [:featured]) }
        .to raise_error(
          Philiprehberger::TestFactory::Error,
          'Trait :featured for factory :post is not defined'
        )
    end

    it 'applies three traits in sequence' do
      described_class.define(:user) { { name: 'Alice', role: 'user', active: true, verified: false } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.trait(:user, :inactive) { { active: false } }
      described_class.trait(:user, :verified) { { verified: true } }

      result = described_class.build(:user, traits: %i[admin inactive verified])

      expect(result).to eq(name: 'Alice', role: 'admin', active: false, verified: true)
    end
  end

  describe '.build_list (edge cases)' do
    it 'builds a list with count of one' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_list(:user, 1)

      expect(results.size).to eq(1)
      expect(results.first).to eq(name: 'Alice')
    end

    it 'returns independent hash objects for each item' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_list(:user, 2)

      results.first[:name] = 'Modified'
      expect(results.last[:name]).to eq('Alice')
    end

    it 'applies both traits and overrides to each item' do
      described_class.define(:user) { { name: 'Alice', role: 'user', active: true } }
      described_class.trait(:user, :inactive) { { active: false } }

      results = described_class.build_list(:user, 2, traits: [:inactive], name: 'Bob')

      results.each do |r|
        expect(r[:name]).to eq('Bob')
        expect(r[:active]).to eq(false)
        expect(r[:role]).to eq('user')
      end
    end
  end

  describe '.sequence (edge cases)' do
    it 'generates sequential values when used inside a factory' do
      described_class.sequence(:email) { |n| "user_#{n}@example.com" }
      described_class.define(:user) do
        { name: 'User', email: described_class.send(:registry).next_in_sequence(:email) }
      end

      u1 = described_class.build(:user)
      u2 = described_class.build(:user)

      expect(u1[:email]).to eq('user_1@example.com')
      expect(u2[:email]).to eq('user_2@example.com')
    end

    it 'supports sequences returning complex objects' do
      described_class.sequence(:record) { |n| { id: n, ref: "REF-#{n}" } }

      v1 = described_class.send(:registry).next_in_sequence(:record)
      v2 = described_class.send(:registry).next_in_sequence(:record)

      expect(v1).to eq(id: 1, ref: 'REF-1')
      expect(v2).to eq(id: 2, ref: 'REF-2')
    end

    it 'continues incrementing across many calls' do
      described_class.sequence(:nums) { |n| n }

      results = Array.new(10) { described_class.send(:registry).next_in_sequence(:nums) }

      expect(results).to eq((1..10).to_a)
    end
  end

  describe Philiprehberger::TestFactory::Registry do
    subject(:registry) { described_class.new }

    it 'returns nil for undefined factory' do
      expect(registry.get(:nonexistent)).to be_nil
    end

    it 'returns nil for undefined trait' do
      expect(registry.get_trait(:user, :admin)).to be_nil
    end

    it 'returns nil for trait on factory with no traits' do
      registry.define(:user) { { name: 'Alice' } }

      expect(registry.get_trait(:user, :admin)).to be_nil
    end

    it 'clears factories, traits, and sequences on clear!' do
      registry.define(:user) { { name: 'Alice' } }
      registry.trait(:user, :admin) { { role: 'admin' } }
      registry.sequence(:counter) { |n| n }

      registry.clear!

      expect(registry.get(:user)).to be_nil
      expect(registry.get_trait(:user, :admin)).to be_nil
      expect { registry.next_in_sequence(:counter) }
        .to raise_error(Philiprehberger::TestFactory::Error)
    end
  end

  describe Philiprehberger::TestFactory::Sequence do
    it 'starts counting from 1' do
      seq = described_class.new { |n| n }

      expect(seq.next).to eq(1)
    end

    it 'increments on each call' do
      seq = described_class.new { |n| n * 10 }

      expect(seq.next).to eq(10)
      expect(seq.next).to eq(20)
      expect(seq.next).to eq(30)
    end
  end

  describe '.reset! (edge cases)' do
    it 'allows redefining everything after reset' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.sequence(:counter) { |n| n }
      described_class.reset!

      described_class.define(:user) { { name: 'Bob' } }
      described_class.trait(:user, :admin) { { role: 'superadmin' } }
      described_class.sequence(:counter) { |n| n * 100 }

      expect(described_class.build(:user, traits: [:admin])).to eq(name: 'Bob', role: 'superadmin')
      expect(described_class.send(:registry).next_in_sequence(:counter)).to eq(100)
    end

    it 'is idempotent when called multiple times' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.reset!
      described_class.reset!
      described_class.reset!

      expect { described_class.build(:user) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :user is not defined/)
    end

    it 'resets sequence counters so they restart from 1' do
      described_class.sequence(:id) { |n| n }
      described_class.send(:registry).next_in_sequence(:id)
      described_class.send(:registry).next_in_sequence(:id)
      described_class.reset!

      described_class.sequence(:id) { |n| n }

      expect(described_class.send(:registry).next_in_sequence(:id)).to eq(1)
    end
  end

  describe 'sequences inside factories' do
    it 'produces unique emails across build_list items' do
      described_class.sequence(:email) { |n| "user_#{n}@test.com" }
      described_class.define(:user) do
        { name: 'User', email: described_class.send(:registry).next_in_sequence(:email) }
      end

      results = described_class.build_list(:user, 3)

      emails = results.map { |r| r[:email] }
      expect(emails).to eq(['user_1@test.com', 'user_2@test.com', 'user_3@test.com'])
    end

    it 'produces unique ids when sequence is used for numeric fields' do
      described_class.sequence(:id) { |n| n }
      described_class.define(:record) do
        { id: described_class.send(:registry).next_in_sequence(:id), value: 'data' }
      end

      r1 = described_class.build(:record)
      r2 = described_class.build(:record)

      expect(r1[:id]).to eq(1)
      expect(r2[:id]).to eq(2)
    end

    it 'sequences continue incrementing across traits and overrides' do
      described_class.sequence(:slug) { |n| "slug-#{n}" }
      described_class.define(:post) do
        { slug: described_class.send(:registry).next_in_sequence(:slug), status: 'draft' }
      end
      described_class.trait(:post, :published) { { status: 'published' } }

      p1 = described_class.build(:post, traits: [:published], title: 'First')
      p2 = described_class.build(:post)

      expect(p1[:slug]).to eq('slug-1')
      expect(p2[:slug]).to eq('slug-2')
    end
  end

  describe 'override edge cases' do
    it 'supports overriding a value with zero' do
      described_class.define(:product) { { name: 'Widget', price: 9.99 } }

      result = described_class.build(:product, price: 0)

      expect(result[:price]).to eq(0)
    end

    it 'supports overriding a value with an empty string' do
      described_class.define(:user) { { name: 'Alice', bio: 'Hello world' } }

      result = described_class.build(:user, bio: '')

      expect(result[:bio]).to eq('')
    end

    it 'supports overriding a value with an empty array' do
      described_class.define(:post) { { title: 'Hello', tags: %w[ruby test] } }

      result = described_class.build(:post, tags: [])

      expect(result[:tags]).to eq([])
    end

    it 'supports overriding a value with false' do
      described_class.define(:feature) { { enabled: true, name: 'dark_mode' } }

      result = described_class.build(:feature, enabled: false)

      expect(result[:enabled]).to eq(false)
    end

    it 'supports adding multiple new attributes via overrides' do
      described_class.define(:user) { { name: 'Alice' } }

      result = described_class.build(:user, age: 30, role: 'admin', active: true)

      expect(result).to eq(name: 'Alice', age: 30, role: 'admin', active: true)
    end
  end

  describe 'trait edge cases (advanced)' do
    it 'trait can override a value with nil' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }
      described_class.trait(:user, :no_email) { { email: nil } }

      result = described_class.build(:user, traits: [:no_email])

      expect(result).to eq(name: 'Alice', email: nil)
    end

    it 'trait can override a value with false' do
      described_class.define(:user) { { name: 'Alice', active: true } }
      described_class.trait(:user, :deactivated) { { active: false } }

      result = described_class.build(:user, traits: [:deactivated])

      expect(result[:active]).to eq(false)
    end

    it 'raises for undefined trait even when factory exists with other traits' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      expect { described_class.build(:user, traits: [:moderator]) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Trait :moderator for factory :user is not defined')
    end

    it 'raises for trait on second factory when first factory has that trait name' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) { { title: 'Hello' } }
      described_class.trait(:user, :special) { { role: 'special' } }

      expect { described_class.build(:post, traits: [:special]) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Trait :special for factory :post is not defined')
    end
  end

  describe Philiprehberger::TestFactory::Builder do
    let(:registry) { Philiprehberger::TestFactory::Registry.new }
    let(:builder) { described_class.new(registry) }

    it 'builds from a registered factory' do
      registry.define(:item) { { name: 'thing' } }

      result = builder.build(:item)

      expect(result).to eq(name: 'thing')
    end

    it 'raises Error for an undefined factory' do
      expect { builder.build(:missing) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Factory :missing is not defined')
    end

    it 'applies overrides to the built hash' do
      registry.define(:item) { { name: 'thing', qty: 1 } }

      result = builder.build(:item, qty: 5)

      expect(result).to eq(name: 'thing', qty: 5)
    end

    it 'applies traits via the registry' do
      registry.define(:item) { { name: 'thing', status: 'active' } }
      registry.trait(:item, :archived) { { status: 'archived' } }

      result = builder.build(:item, traits: [:archived])

      expect(result).to eq(name: 'thing', status: 'archived')
    end

    it 'build_list produces the requested count' do
      registry.define(:item) { { name: 'thing' } }

      results = builder.build_list(:item, 4)

      expect(results.size).to eq(4)
      expect(results).to all(eq(name: 'thing'))
    end

    it 'build_list raises for undefined factory' do
      expect { builder.build_list(:missing, 2) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Factory :missing is not defined')
    end
  end

  describe Philiprehberger::TestFactory::Registry, 'advanced' do
    subject(:registry) { described_class.new }

    it 'stores and retrieves multiple factories independently' do
      registry.define(:a) { { x: 1 } }
      registry.define(:b) { { y: 2 } }

      expect(registry.get(:a).call).to eq(x: 1)
      expect(registry.get(:b).call).to eq(y: 2)
    end

    it 'redefining a sequence resets its counter' do
      registry.sequence(:id) { |n| n }
      registry.next_in_sequence(:id)
      registry.next_in_sequence(:id)

      registry.sequence(:id) { |n| n * 10 }

      expect(registry.next_in_sequence(:id)).to eq(10)
    end

    it 'raises with correct message for undefined sequence' do
      expect { registry.next_in_sequence(:unknown) }
        .to raise_error(Philiprehberger::TestFactory::Error, 'Sequence :unknown is not defined')
    end
  end

  describe Philiprehberger::TestFactory::Sequence, 'advanced' do
    it 'supports sequences returning strings' do
      seq = described_class.new { |n| "item-#{n}" }

      expect(seq.next).to eq('item-1')
      expect(seq.next).to eq('item-2')
    end

    it 'supports sequences returning arrays' do
      seq = described_class.new { |n| [n, n * 2] }

      expect(seq.next).to eq([1, 2])
      expect(seq.next).to eq([2, 4])
    end

    it 'supports sequences returning nil' do
      seq = described_class.new { |_n| nil }

      expect(seq.next).to be_nil
      expect(seq.next).to be_nil
    end
  end
end
