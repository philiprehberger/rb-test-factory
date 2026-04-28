# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TestFactory do
  before { Philiprehberger::TestFactory.reset! }

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

    it 'raises ArgumentError for a negative count' do
      described_class.define(:user) { { name: 'Alice' } }

      expect { described_class.build_list(:user, -1) }
        .to raise_error(ArgumentError, /count must be non-negative/)
    end

    it 'raises ArgumentError for a large negative count' do
      described_class.define(:user) { { name: 'Alice' } }

      expect { described_class.build_list(:user, -10) }
        .to raise_error(ArgumentError, /count must be non-negative/)
    end

    it 'returns distinct object instances per element' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_list(:user, 3)

      expect(results.map(&:object_id).uniq.size).to eq(3)
    end

    it 'propagates sequences so each element has a unique value' do
      described_class.sequence(:email) { |n| "user_#{n}@example.com" }
      described_class.define(:user) do
        { name: 'User', email: described_class.send(:registry).next_in_sequence(:email) }
      end

      results = described_class.build_list(:user, 4)

      emails = results.map { |r| r[:email] }
      expect(emails).to eq(
        ['user_1@example.com', 'user_2@example.com', 'user_3@example.com', 'user_4@example.com']
      )
      expect(emails.uniq.size).to eq(4)
    end

    it 'applies identical overrides to every element in the list' do
      described_class.define(:user) { { name: 'Alice', role: 'user', active: true } }

      results = described_class.build_list(:user, 3, name: 'Bob', role: 'admin')

      results.each do |r|
        expect(r[:name]).to eq('Bob')
        expect(r[:role]).to eq('admin')
        expect(r[:active]).to eq(true)
      end
    end
  end

  describe '.build_pair' do
    it 'returns exactly two items' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_pair(:user)

      expect(results.size).to eq(2)
      expect(results).to all(eq(name: 'Alice'))
    end

    it 'applies overrides and traits to both items' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      results = described_class.build_pair(:user, traits: [:admin], name: 'Bob')

      expect(results).to all(include(name: 'Bob', role: 'admin'))
    end

    it 'produces distinct object instances' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_pair(:user)

      expect(results[0]).not_to be(results[1])
    end
  end

  describe '.build_trio' do
    it 'returns exactly three items' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_trio(:user)

      expect(results.size).to eq(3)
      expect(results).to all(eq(name: 'Alice'))
    end

    it 'applies overrides and traits to all three items' do
      described_class.define(:user) { { name: 'Alice', role: 'user' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }

      results = described_class.build_trio(:user, traits: [:admin], name: 'Bob')

      expect(results).to all(include(name: 'Bob', role: 'admin'))
    end

    it 'produces distinct object instances' do
      described_class.define(:user) { { name: 'Alice' } }

      results = described_class.build_trio(:user)

      expect(results[0]).not_to be(results[1])
      expect(results[1]).not_to be(results[2])
      expect(results[0]).not_to be(results[2])
    end

    it 'increments sequences once per item' do
      described_class.sequence(:id) { |n| n }
      described_class.define(:user) do
        { id: described_class.send(:registry).next_in_sequence(:id), name: 'User' }
      end

      results = described_class.build_trio(:user)

      expect(results.map { |r| r[:id] }).to eq([1, 2, 3])
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

  describe '.factories and .defined?' do
    it 'returns an empty array when nothing is registered' do
      expect(described_class.factories).to eq([])
    end

    it 'lists factory names in registration order' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) { { title: 'Hello' } }
      described_class.define(:comment) { { body: 'Nice' } }

      expect(described_class.factories).to eq(%i[user post comment])
    end

    it 'does not include traits or sequences' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.trait(:user, :admin) { { role: 'admin' } }
      described_class.sequence(:n) { |i| i }

      expect(described_class.factories).to eq([:user])
    end

    it 'returns true for a registered factory' do
      described_class.define(:user) { { name: 'Alice' } }

      expect(described_class.defined?(:user)).to be(true)
    end

    it 'returns false for an unknown factory name' do
      expect(described_class.defined?(:nope)).to be(false)
    end

    it 'returns false after reset!' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.reset!

      expect(described_class.defined?(:user)).to be(false)
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

    it 'build_list raises ArgumentError for a negative count' do
      registry.define(:item) { { name: 'thing' } }

      expect { builder.build_list(:item, -1) }
        .to raise_error(ArgumentError, /count must be non-negative/)
    end

    it 'build_list returns [] for count == 0' do
      registry.define(:item) { { name: 'thing' } }

      expect(builder.build_list(:item, 0)).to eq([])
    end
  end

  describe Philiprehberger::TestFactory::Registry, 'advanced' do
    subject(:registry) { described_class.new }

    it 'stores and retrieves multiple factories independently' do
      registry.define(:a) { { x: 1 } }
      registry.define(:b) { { y: 2 } }

      entry_a = registry.get(:a)
      entry_b = registry.get(:b)

      expect(entry_a[:proxy].instance_exec(entry_a[:proxy], &entry_a[:block])).to eq(x: 1)
      expect(entry_b[:proxy].instance_exec(entry_b[:proxy], &entry_b[:block])).to eq(y: 2)
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

  describe 'after_build callbacks' do
    it 'runs a single after_build callback' do
      described_class.define(:user) do |f|
        f.after_build { |obj| obj[:created_at] = '2026-01-01' }
        { name: 'Alice', email: 'alice@example.com' }
      end

      result = described_class.build(:user)

      expect(result[:name]).to eq('Alice')
      expect(result[:created_at]).to eq('2026-01-01')
    end

    it 'runs multiple after_build callbacks in order' do
      described_class.define(:user) do |f|
        f.after_build { |obj| obj[:step1] = true }
        f.after_build { |obj| obj[:step2] = true }
        f.after_build { |obj| obj[:step3] = true }
        { name: 'Alice' }
      end

      result = described_class.build(:user)

      expect(result[:step1]).to eq(true)
      expect(result[:step2]).to eq(true)
      expect(result[:step3]).to eq(true)
    end

    it 'callback can modify existing attributes' do
      described_class.define(:user) do |f|
        f.after_build { |obj| obj[:name] = obj[:name].upcase }
        { name: 'Alice' }
      end

      result = described_class.build(:user)

      expect(result[:name]).to eq('ALICE')
    end

    it 'callback runs after overrides are applied' do
      described_class.define(:user) do |f|
        f.after_build { |obj| obj[:name] = obj[:name].upcase }
        { name: 'Alice' }
      end

      result = described_class.build(:user, name: 'Bob')

      expect(result[:name]).to eq('BOB')
    end

    it 'callback runs after traits are applied' do
      described_class.define(:user) do |f|
        f.after_build { |obj| obj[:summary] = "#{obj[:name]}-#{obj[:role]}" }
        { name: 'Alice', role: 'user' }
      end
      described_class.trait(:user, :admin) { { role: 'admin' } }

      result = described_class.build(:user, traits: [:admin])

      expect(result[:summary]).to eq('Alice-admin')
    end

    it 'callbacks work with build_list' do
      counter = 0
      described_class.define(:item) do |f|
        f.after_build do |obj|
          counter += 1
          obj[:build_order] = counter
        end
        { name: 'thing' }
      end

      results = described_class.build_list(:item, 3)

      expect(results.map { |r| r[:build_order] }).to eq([1, 2, 3])
    end

    it 'factory with no callbacks works normally' do
      described_class.define(:user) { { name: 'Alice' } }

      result = described_class.build(:user)

      expect(result).to eq(name: 'Alice')
    end
  end

  describe 'transient attributes' do
    it 'excludes transient attributes from the final hash' do
      described_class.define(:user) do |f|
        f.transient { admin false }
        { name: 'Alice', role: 'user' }
      end

      result = described_class.build(:user)

      expect(result).to eq(name: 'Alice', role: 'user')
      expect(result).not_to have_key(:admin)
    end

    it 'transient attributes are accessible in after_build callbacks' do
      described_class.define(:user) do |f|
        f.transient { admin false }
        f.after_build { |obj, transients| obj[:role] = 'admin' if transients[:admin] }
        { name: 'Alice', role: 'user' }
      end

      result = described_class.build(:user, admin: true)

      expect(result[:role]).to eq('admin')
      expect(result).not_to have_key(:admin)
    end

    it 'transient attributes use defaults when not overridden' do
      described_class.define(:user) do |f|
        f.transient { admin false }
        f.after_build { |obj, transients| obj[:role] = 'admin' if transients[:admin] }
        { name: 'Alice', role: 'user' }
      end

      result = described_class.build(:user)

      expect(result[:role]).to eq('user')
    end

    it 'multiple transient attributes can be declared' do
      described_class.define(:user) do |f|
        f.transient do
          admin false
          confirmed true
        end
        f.after_build do |obj, transients|
          obj[:role] = 'admin' if transients[:admin]
          obj[:confirmed_at] = '2026-01-01' if transients[:confirmed]
        end
        { name: 'Alice', role: 'user' }
      end

      result = described_class.build(:user, admin: true, confirmed: true)

      expect(result[:role]).to eq('admin')
      expect(result[:confirmed_at]).to eq('2026-01-01')
      expect(result).not_to have_key(:admin)
      expect(result).not_to have_key(:confirmed)
    end

    it 'transient attributes work with build_list' do
      described_class.define(:user) do |f|
        f.transient { uppercase false }
        f.after_build { |obj, transients| obj[:name] = obj[:name].upcase if transients[:uppercase] }
        { name: 'Alice' }
      end

      results = described_class.build_list(:user, 2, uppercase: true)

      expect(results).to all(include(name: 'ALICE'))
      results.each { |r| expect(r).not_to have_key(:uppercase) }
    end

    it 'transient defaults with nil value' do
      described_class.define(:user) do |f|
        f.transient { token nil }
        f.after_build { |obj, transients| obj[:token] = transients[:token] if transients[:token] }
        { name: 'Alice' }
      end

      result_without = described_class.build(:user)
      result_with = described_class.build(:user, token: 'abc123')

      expect(result_without).to eq(name: 'Alice')
      expect(result_with).to eq(name: 'Alice', token: 'abc123')
    end
  end

  describe 'associations' do
    it 'builds an associated factory' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        { title: 'Hello World', body: 'Content here' }
      end

      result = described_class.build(:post)

      expect(result[:title]).to eq('Hello World')
      expect(result[:author]).to eq(name: 'Alice', email: 'alice@example.com')
    end

    it 'overrides association with a plain hash' do
      described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        { title: 'Hello World' }
      end

      result = described_class.build(:post, author: { name: 'Custom' })

      expect(result[:author]).to eq(name: 'Custom')
    end

    it 'overrides association with nil' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        { title: 'Hello' }
      end

      result = described_class.build(:post, author: nil)

      expect(result[:author]).to be_nil
    end

    it 'uses attribute name as factory name when factory option is omitted' do
      described_class.define(:author) { { name: 'Alice' } }
      described_class.define(:post) do |f|
        f.association :author
        { title: 'Hello' }
      end

      result = described_class.build(:post)

      expect(result[:author]).to eq(name: 'Alice')
    end

    it 'supports multiple associations' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:category) { { name: 'Tech' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        f.association :category
        { title: 'Hello' }
      end

      result = described_class.build(:post)

      expect(result[:author]).to eq(name: 'Alice')
      expect(result[:category]).to eq(name: 'Tech')
      expect(result[:title]).to eq('Hello')
    end

    it 'associations work with build_list' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        { title: 'Hello' }
      end

      results = described_class.build_list(:post, 2)

      results.each do |r|
        expect(r[:author]).to eq(name: 'Alice')
      end
    end

    it 'associated factory uses its own sequences' do
      described_class.sequence(:user_email) { |n| "user_#{n}@example.com" }
      described_class.define(:user) do
        { name: 'Alice', email: described_class.send(:registry).next_in_sequence(:user_email) }
      end
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        { title: 'Hello' }
      end

      r1 = described_class.build(:post)
      r2 = described_class.build(:post)

      expect(r1[:author][:email]).to eq('user_1@example.com')
      expect(r2[:author][:email]).to eq('user_2@example.com')
    end

    it 'raises for undefined associated factory' do
      described_class.define(:post) do |f|
        f.association :author, factory: :nonexistent
        { title: 'Hello' }
      end

      expect { described_class.build(:post) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end
  end

  describe 'callbacks, transients, and associations together' do
    it 'supports all three features in one factory' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) do |f|
        f.transient { publish false }
        f.association :author, factory: :user
        f.after_build { |obj, transients| obj[:status] = 'published' if transients[:publish] }
        { title: 'Hello', status: 'draft' }
      end

      draft = described_class.build(:post)
      published = described_class.build(:post, publish: true)

      expect(draft[:status]).to eq('draft')
      expect(draft[:author]).to eq(name: 'Alice')
      expect(draft).not_to have_key(:publish)

      expect(published[:status]).to eq('published')
      expect(published[:author]).to eq(name: 'Alice')
      expect(published).not_to have_key(:publish)
    end

    it 'after_build can access association values' do
      described_class.define(:user) { { name: 'Alice' } }
      described_class.define(:post) do |f|
        f.association :author, factory: :user
        f.after_build { |obj| obj[:author_name] = obj[:author][:name] }
        { title: 'Hello' }
      end

      result = described_class.build(:post)

      expect(result[:author_name]).to eq('Alice')
    end
  end

  describe Philiprehberger::TestFactory::DefinitionProxy do
    subject(:proxy) { described_class.new }

    it 'starts with empty callbacks' do
      expect(proxy.after_build_callbacks).to eq([])
    end

    it 'starts with empty transient attributes' do
      expect(proxy.transient_attributes).to eq({})
    end

    it 'starts with empty associations' do
      expect(proxy.associations).to eq({})
    end

    it 'registers after_build callbacks' do
      proxy.after_build { |obj| obj[:x] = 1 }
      proxy.after_build { |obj| obj[:y] = 2 }

      expect(proxy.after_build_callbacks.size).to eq(2)
    end

    it 'collects transient attributes' do
      proxy.transient do
        admin false
        score 100
      end

      expect(proxy.transient_attributes).to eq(admin: false, score: 100)
    end

    it 'registers associations with explicit factory' do
      proxy.association :author, factory: :user

      expect(proxy.associations).to eq(author: :user)
    end

    it 'registers associations defaulting to attribute name' do
      proxy.association :category

      expect(proxy.associations).to eq(category: :category)
    end
  end

  describe Philiprehberger::TestFactory::TransientCollector do
    subject(:collector) { described_class.new }

    it 'collects attributes via method calls' do
      collector.instance_eval do
        admin false
        count 5
        label 'test'
      end

      expect(collector.attributes).to eq(admin: false, count: 5, label: 'test')
    end

    it 'starts with empty attributes' do
      expect(collector.attributes).to eq({})
    end
  end
end
