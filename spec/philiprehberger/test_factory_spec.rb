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
  end

  describe ".build_list" do
    it "returns the correct number of items" do
      described_class.define(:user) { { name: "Alice" } }

      results = described_class.build_list(:user, 3)

      expect(results.size).to eq(3)
      expect(results).to all(eq(name: "Alice"))
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
  end

  describe ".sequence" do
    it "auto-increments values" do
      described_class.sequence(:email) { |n| "user_#{n}@example.com" }
      described_class.define(:user) { { email: described_class.build_sequence(:email) } } # won't work this way

      # Use sequence directly via the registry
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
  end

  describe ".reset!" do
    it "clears all definitions" do
      described_class.define(:user) { { name: "Alice" } }
      described_class.reset!

      expect { described_class.build(:user) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :user is not defined/)
    end
  end

  describe "error handling" do
    it "raises an error for undefined factories" do
      expect { described_class.build(:nonexistent) }
        .to raise_error(Philiprehberger::TestFactory::Error, /Factory :nonexistent is not defined/)
    end
  end
end
