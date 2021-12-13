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
        entry = @registry.get(name)
        raise Error, "Factory :#{name} is not defined" unless entry

        block = entry[:block]
        proxy = entry[:proxy]

        # Evaluate the definition block to get fresh default attributes.
        # For blocks accepting a proxy parameter, use a NullProxy to discard
        # DSL re-registrations (they were already captured at define time).
        result = if block.arity.zero?
                   block.call
                 else
                   null_proxy = NullProxy.new
                   null_proxy.instance_exec(null_proxy, &block)
                 end

        # Apply traits
        traits.each { |t| result = apply_trait(name, t, result) }

        # Separate transient overrides from regular overrides
        transient_keys = proxy.transient_attributes.keys
        transient_values = proxy.transient_attributes.dup
        regular_overrides = {}

        overrides.each do |key, value|
          if transient_keys.include?(key)
            transient_values[key] = value
          else
            regular_overrides[key] = value
          end
        end

        # Build associations
        proxy.associations.each do |attr_name, factory_name|
          result[attr_name] = if regular_overrides.key?(attr_name)
                                # If overridden, use the override directly (no factory build)
                                regular_overrides.delete(attr_name)
                              else
                                build(factory_name)
                              end
        end

        # Apply regular overrides
        result.merge!(regular_overrides)

        # Remove transient attributes from the result
        transient_keys.each { |key| result.delete(key) }

        # Run after_build callbacks with the result and transient context
        proxy.after_build_callbacks.each { |cb| cb.call(result, transient_values) }

        result
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
