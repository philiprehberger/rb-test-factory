# frozen_string_literal: true

require "spec_helper"

RSpec.describe Philiprehberger::TestFactory do
  before { described_class.reset! }

  it "has a version number" do
    expect(Philiprehberger::TestFactory::VERSION).not_to be_nil
  end

  describe ".define and .build" do
    it "defines and builds a simple factory" do
      described_class.define(:user) { { name: "Alice", email: "alice@example.com" } }

      result = described_class.build(:user)

      expect(result).to eq(name: "Alice", email: "alice@example.com")
    end

    it "builds with overrides" do
      described_class.define(:user) { { name: "Alice", email: "alice@example.com" } }

      result = described_class.build(:user, name: "Bob")

      expect(result).to eq(name: "Bob", email: "alice@example.com")
    end

    it "builds an empty factory" do
      described_class.define(:empty) { {} }

      result = described_class.build(:empty)

      expect(result).to eq({})
    end

    it "builds with no overrides" do
      described_class.define(:post) { { title: "Hello" } }

      result = described_class.build(:post)

      expect(result).to eq(title: "Hello")
    end

    it "allows overriding all attributes" do
      described_class.define(:user) { { name: "Alice", email: "alice@example.com" } }

      result = described_class.build(:user, name: "Bob", email: "bob@example.com")

      expect(result).to eq(name: "Bob", email: "bob@example.com")
    end

    it "allows adding attributes not in the factory definition" do
      described_class.define(:user) { { name: "Alice" } }

      result = described_class.build(:user, age: 30)

      expect(result).to eq(name: "Alice", age: 30)
    end

    it "supports factories with many attributes" do
      described_class.define(:profile) do
        {
          name: "Alice",
          email: "alice@example.com",
          age: 25,
          role: "user",
          active: true,
          score: 100
        }
      end

      result = described_class.build(:profile)

      expect(result.keys.size).to eq(6)
    end

    it "calls the factory block each time to get fresh defaults" do
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

    it "redefines a factory when called again with the same name" do
      described_class.define(:user) { { name: "Alice" } }
      described_class.define(:user) { { name: "Bob" } }

      result = described_class.build(:user)

      expect(result).to eq(name: "Bob")
    end
  end

  describe ".build_list" do
    it "returns the correct number of items" do
      described_class.define(:user) { { name: "Alice" } }

      results = described_class.build_list(:user, 3)

      expect(results.size).to eq(3)
      expect(results).to all(eq(name: "Alice"))
    end

    it "returns an empty array when count is zero" do
      described_class.define(:user) { { name: "Alice" } }

      results = described_class.build_list(:user, 0)

      expect(results).to eq([])
    end

    it "applies overrides to each item in the list" do
      described_class.define(:user) { { name: "Alice", role: "user" } }

      results = described_class.build_list(:user, 3, role: "admin")

      expect(results).to all(include(role: "admin"))
    end

    it "applies traits to each item in the list" do
      described_class.define(:user) { { name: "Alice", role: "user" } }
      described_class.trait(:user, :admin) { { role: "admin" } }

      results = described_class.build_list(:user, 2, traits: [:admin])

      expect(results).to all(include(role: "admin"))
    end

    it "calls factory block independently for each item" do
      counter = 0
      described_class.define(:item) do
        counter += 1
        { id: counter }
      end

      results = described_class.build_list(:item, 3)

      expect(results.map { |r| r[:id] }).to eq([1, 2, 3])
    end

    it "raises an error for undefined factory" do
      expect { described_class.build_list(:nonexistent, 2) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end
  end

  describe ".trait" do
    it "overrides specific fields with a trait" do
      described_class.define(:user) { { name: "Alice", role: "user", active: true } }
      described_class.trait(:user, :admin) { { role: "admin" } }

      result = described_class.build(:user, traits: [:admin])

      expect(result).to eq(name: "Alice", role: "admin", active: true)
    end

    it "applies multiple traits in order" do
      described_class.define(:user) { { name: "Alice", role: "user", active: true } }
      described_class.trait(:user, :admin) { { role: "admin" } }
      described_class.trait(:user, :inactive) { { active: false } }

      result = described_class.build(:user, traits: %i[admin inactive])

      expect(result).to eq(name: "Alice", role: "admin", active: false)
    end

    it "raises an error for undefined traits" do
      described_class.define(:user) { { name: "Alice" } }

      expect { described_class.build(:user, traits: [:unknown]) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Trait :unknown/)
    end

    it "last trait wins when traits conflict" do
      described_class.define(:user) { { role: "user" } }
      described_class.trait(:user, :admin) { { role: "admin" } }
      described_class.trait(:user, :superadmin) { { role: "superadmin" } }

      result = described_class.build(:user, traits: %i[admin superadmin])

      expect(result[:role]).to eq("superadmin")
    end

    it "overrides take precedence over traits" do
      described_class.define(:user) { { name: "Alice", role: "user" } }
      described_class.trait(:user, :admin) { { role: "admin" } }

      result = described_class.build(:user, traits: [:admin], role: "superadmin")

      expect(result[:role]).to eq("superadmin")
    end

    it "supports traits that add new attributes" do
      described_class.define(:user) { { name: "Alice" } }
      described_class.trait(:user, :with_email) { { email: "alice@example.com" } }

      result = described_class.build(:user, traits: [:with_email])

      expect(result).to eq(name: "Alice", email: "alice@example.com")
    end

    it "supports an empty traits array" do
      described_class.define(:user) { { name: "Alice" } }

      result = described_class.build(:user, traits: [])

      expect(result).to eq(name: "Alice")
    end
  end

  describe ".sequence" do
    it "auto-increments values" do
      described_class.sequence(:counter) { |n| n }

      results = Array.new(3) { described_class.send(:registry).next_in_sequence(:counter) }

      expect(results).to eq([1, 2, 3])
    end

    it "is thread-safe" do
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

    it "supports string sequences" do
      described_class.sequence(:email) { |n| "user_#{n}@example.com" }

      val = described_class.send(:registry).next_in_sequence(:email)

      expect(val).to eq("user_1@example.com")
    end

    it "raises for undefined sequence" do
      expect { described_class.send(:registry).next_in_sequence(:missing) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Sequence :missing is not defined/)
    end

    it "maintains independent counters per sequence" do
      described_class.sequence(:seq_a) { |n| "a_#{n}" }
      described_class.sequence(:seq_b) { |n| "b_#{n}" }

      a1 = described_class.send(:registry).next_in_sequence(:seq_a)
      b1 = described_class.send(:registry).next_in_sequence(:seq_b)
      a2 = described_class.send(:registry).next_in_sequence(:seq_a)

      expect(a1).to eq("a_1")
      expect(b1).to eq("b_1")
      expect(a2).to eq("a_2")
    end
  end

  describe ".reset!" do
    it "clears all definitions" do
      described_class.define(:user) { { name: "Alice" } }
      described_class.reset!

      expect { described_class.build(:user) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :user is not defined/)
    end

    it "clears all traits" do
      described_class.define(:user) { { name: "Alice" } }
      described_class.trait(:user, :admin) { { role: "admin" } }
      described_class.reset!
      described_class.define(:user) { { name: "Alice" } }

      expect { described_class.build(:user, traits: [:admin]) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Trait :admin/)
    end

    it "clears all sequences" do
      described_class.sequence(:counter) { |n| n }
      described_class.reset!

      expect { described_class.send(:registry).next_in_sequence(:counter) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Sequence :counter is not defined/)
    end
  end

  describe "error handling" do
    it "raises an error for undefined factories" do
      expect { described_class.build(:nonexistent) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end

    it "error class inherits from StandardError" do
      expect(Philiprehberger::TestFactory::Error.ancestors).to include(StandardError)
    end
  end
end
