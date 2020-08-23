# frozen_string_literal: true

require_relative 'sequence'

module Philiprehberger
  module TestFactory
    # Stores factory definitions, traits, and sequences.
    class Registry
      def initialize
        clear!
      end

      # Register a factory definition.
      #
      # @param name [Symbol] factory name
      # @param block [Proc] block returning a hash of default attributes
      # @return [void]
      def define(name, &block)
        @factories[name] = block
      end

      # Register a trait override for a factory.
      #
      # @param factory_name [Symbol] factory name
      # @param trait_name [Symbol] trait name
      # @param block [Proc] block returning a hash of overridden attributes
      # @return [void]
      def trait(factory_name, trait_name, &block)
        @traits[factory_name] ||= {}
        @traits[factory_name][trait_name] = block
      end

      # Register a sequence generator.
      #
      # @param name [Symbol] sequence name
      # @param block [Proc] block receiving an integer counter
      # @return [void]
      def sequence(name, &)
        @sequences[name] = Sequence.new(&)
      end

      # Retrieve a factory definition.
      #
      # @param name [Symbol] factory name
      # @return [Proc, nil] the factory block or nil
      def get(name)
        @factories[name]
      end

      # Retrieve a trait for a factory.
      #
      # @param factory_name [Symbol] factory name
      # @param trait_name [Symbol] trait name
      # @return [Proc, nil] the trait block or nil
      def get_trait(factory_name, trait_name)
        @traits.dig(factory_name, trait_name)
      end

      # Get the next value from a named sequence.
      #
      # @param name [Symbol] sequence name
      # @return [Object] the next sequence value
      # @raise [Error] if the sequence is not defined
      def next_in_sequence(name)
        seq = @sequences[name]
        raise Error, "Sequence :#{name} is not defined" unless seq

        seq.next
      end

      # Reset all definitions, traits, and sequences.
      #
      # @return [void]
      def clear!
        @factories = {}
        @traits = {}
        @sequences = {}
      end
    end
  end
end
