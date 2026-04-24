# frozen_string_literal: true

require_relative 'test_factory/version'
require_relative 'test_factory/sequence'
require_relative 'test_factory/definition_proxy'
require_relative 'test_factory/registry'
require_relative 'test_factory/builder'

module Philiprehberger
  # Lightweight DSL for building test data objects without ActiveRecord.
  module TestFactory
    class Error < StandardError; end

    class << self
      # Register a factory definition.
      #
      # @param name [Symbol] factory name
      # @param block [Proc] block returning a hash of default attributes
      # @return [void]
      def define(name, &)
        registry.define(name, &)
      end

      # Register a trait override for a factory.
      #
      # @param factory_name [Symbol] factory name
      # @param trait_name [Symbol] trait name
      # @param block [Proc] block returning overridden attributes
      # @return [void]
      def trait(factory_name, trait_name, &)
        registry.trait(factory_name, trait_name, &)
      end

      # Register a sequence generator.
      #
      # @param name [Symbol] sequence name
      # @param block [Proc] block receiving an integer counter
      # @return [void]
      def sequence(name, &)
        registry.sequence(name, &)
      end

      # Build a single data hash from a factory.
      #
      # @param name [Symbol] factory name
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Hash] the built data hash
      def build(name, traits: [], **overrides)
        builder.build(name, traits: traits, **overrides)
      end

      # Build a list of data hashes from a factory.
      #
      # @param name [Symbol] factory name
      # @param count [Integer] number of items to build
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Array<Hash>] the built data hashes
      def build_list(name, count, traits: [], **overrides)
        builder.build_list(name, count, traits: traits, **overrides)
      end

      # Build exactly two data hashes from a factory. Convenience shortcut
      # around {#build_list} mirroring FactoryBot's `build_pair`.
      #
      # @param name [Symbol] factory name
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Array<Hash>] two built data hashes
      def build_pair(name, traits: [], **overrides)
        builder.build_list(name, 2, traits: traits, **overrides)
      end

      # Build exactly three data hashes from a factory. Convenience shortcut
      # around {#build_list} completing the `build` / `build_pair` / `build_trio`
      # progression.
      #
      # @param name [Symbol] factory name
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Array<Hash>] three built data hashes
      def build_trio(name, traits: [], **overrides)
        builder.build_list(name, 3, traits: traits, **overrides)
      end

      # Resolve the attribute hash without firing after_build callbacks or
      # resolving associations. Mirrors FactoryBot's `attributes_for`.
      #
      # @param name [Symbol] factory name
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Hash] the resolved attribute hash
      def attributes_for(name, traits: [], **overrides)
        builder.attributes_for(name, traits: traits, **overrides)
      end

      # Clear all factory definitions, traits, and sequences.
      #
      # @return [void]
      def reset!
        @registry = nil
        @builder = nil
      end

      private

      def registry
        @registry ||= Registry.new
      end

      def builder
        @builder ||= Builder.new(registry)
      end
    end
  end
end
