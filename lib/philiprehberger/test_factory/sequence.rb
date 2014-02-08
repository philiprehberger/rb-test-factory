# frozen_string_literal: true

module Philiprehberger
  module TestFactory
    # Thread-safe auto-incrementing sequence generator.
    #
    # @example
    #   seq = Sequence.new { |n| "user_#{n}@example.com" }
    #   seq.next # => "user_1@example.com"
    #   seq.next # => "user_2@example.com"
    class Sequence
      # Create a new sequence.
      #
      # @param block [Proc] block receiving an integer counter (starting at 1)
      def initialize(&block)
        @block = block
        @counter = 0
        @mutex = Mutex.new
      end

      # Increment the counter and return the block result.
      #
      # @return [Object] the result of the block with the current counter
      def next
        @mutex.synchronize do
          @counter += 1
          @block.call(@counter)
        end
      end
    end
  end
end
