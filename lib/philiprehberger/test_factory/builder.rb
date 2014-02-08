# frozen_string_literal: true

module Philiprehberger
  module TestFactory
    # Builds data hashes from factory definitions.
    class Builder
      # Create a new builder.
      #
      # @param registry [Registry] the registry to look up definitions
      def initialize(registry)
        @registry = registry
      end

      # Build a single data hash from a factory definition.
      #
      # @param name [Symbol] factory name
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Hash] the built data hash
      # @raise [Error] if the factory is not defined
      def build(name, traits: [], **overrides)
        factory = @registry.get(name)
        raise Error, "Factory :#{name} is not defined" unless factory

        result = factory.call
        traits.each { |t| result = apply_trait(name, t, result) }
        result.merge(overrides)
      end

      # Build a list of data hashes.
      #
      # @param name [Symbol] factory name
      # @param count [Integer] number of items to build
      # @param traits [Array<Symbol>] trait names to apply
      # @param overrides [Hash] explicit attribute overrides
      # @return [Array<Hash>] the built data hashes
      def build_list(name, count, traits: [], **overrides)
        Array.new(count) { build(name, traits: traits, **overrides) }
      end

      private

      def apply_trait(factory_name, trait_name, base)
        trait = @registry.get_trait(factory_name, trait_name)
        raise Error, "Trait :#{trait_name} for factory :#{factory_name} is not defined" unless trait

        base.merge(trait.call)
      end
    end
  end
end
