# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TestFactory, '.attributes_for' do
  before { described_class.reset! }

  it 'returns a plain Hash with declared attributes' do
    described_class.define(:user) { { name: 'Alice', email: 'alice@example.com' } }

    result = described_class.attributes_for(:user)

    expect(result).to be_a(Hash)
    expect(result).to eq(name: 'Alice', email: 'alice@example.com')
  end

  it 'lets overrides win over defaults' do
    described_class.define(:user) { { name: 'Alice', role: 'user' } }

    result = described_class.attributes_for(:user, role: :admin, name: 'Bob')

    expect(result).to eq(name: 'Bob', role: :admin)
  end

  it 'merges traits into the attribute hash' do
    described_class.define(:user) { { name: 'Alice', role: 'user', active: true } }
    described_class.trait(:user, :admin) { { role: 'admin' } }

    result = described_class.attributes_for(:user, traits: [:admin])

    expect(result).to eq(name: 'Alice', role: 'admin', active: true)
  end

  it 'does not invoke after_build callbacks' do
    spy = { called: false }
    described_class.define(:user) do |f|
      f.after_build { |_obj| spy[:called] = true }
      { name: 'Alice' }
    end

    result = described_class.attributes_for(:user)

    expect(spy[:called]).to be(false)
    expect(result).to eq(name: 'Alice')
  end

  it 'represents association fields as nil in the hash' do
    described_class.define(:user) { { name: 'Alice' } }
    described_class.define(:post) do |f|
      f.association :author, factory: :user
      { title: 'Hello' }
    end

    result = described_class.attributes_for(:post)

    expect(result).to eq(title: 'Hello', author: nil)
  end

  it 'still increments sequences per call' do
    described_class.sequence(:email) { |n| "user_#{n}@example.com" }
    described_class.define(:user) do
      { name: 'User', email: described_class.send(:registry).next_in_sequence(:email) }
    end

    r1 = described_class.attributes_for(:user)
    r2 = described_class.attributes_for(:user)

    expect(r1[:email]).to eq('user_1@example.com')
    expect(r2[:email]).to eq('user_2@example.com')
  end
end
