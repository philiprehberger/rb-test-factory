# frozen_string_literal: true

module Philiprehberger
  module TestFactory
    # DSL proxy used inside factory definition blocks.
    # Supports after_build callbacks, transient attributes, and associations.
    class DefinitionProxy
      # @return [Array<Proc>] registered after_build callbacks
      attr_reader :after_build_callbacks

      # @return [Hash] transient attribute defaults
      attr_reader :transient_attributes

      # @return [Hash] association declarations
      attr_reader :associations

      def initialize
        @after_build_callbacks = []
        @transient_attributes = {}
        @associations = {}
      end

      # Register an after_build callback.
      #
      # @yield [Hash] the built object hash
      # @return [void]
      def after_build(&block)
        @after_build_callbacks << block
      end

      # Declare transient attributes that are excluded from the final hash.
      #
      # @yield block that calls attribute setters
      # @return [void]
      def transient(&)
        collector = TransientCollector.new
        collector.instance_eval(&)
        @transient_attributes.merge!(collector.attributes)
      end

      # Declare an association to another factory.
      #
      # @param name [Symbol] the attribute name for the association
      # @param factory [Symbol] the factory to build (defaults to name)
      # @return [void]
      def association(name, factory: name)
        @associations[name] = factory
      end
    end

    # No-op proxy used during build to silently discard DSL calls.
    # The real DSL calls were already captured at define time.
    class NullProxy
      def after_build(&) = nil
      def transient(&) = nil
      def association(_name, **_opts) = nil
    end

    # Collects transient attribute declarations via method_missing.
    class TransientCollector
      # @return [Hash] collected attributes
      attr_reader :attributes

      def initialize
        @attributes = {}
      end

      private

      def method_missing(name, *args)
        if args.length == 1
          @attributes[name] = args.first
        else
          super
        end
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end
    end
  end
end
