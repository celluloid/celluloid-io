module Celluloid
  module IO
    # Tokenize data by a prespecified 1-byte delimiter
    class Tokenizer
      def initialize(delimiter = "\n", size_limit = nil)
        raise TypeError, "invalid #{delimiter.class} delimiter" unless delimiter.is_a? String
        raise ArgumentError, "delimiter must be 1-byte" unless delimiter.length == 1

        @delimiter  = delimiter
        @size_limit = size_limit
        @input = []
        @input_size = 0
      end

      def extract(data)
        entities = data.split(@delimiter, -1)

        if @size_limit
          raise 'input buffer full' if @input_size + entities.first.size > @size_limit
          @input_size += entities.first.size
        end

        @input << entities.shift
        return [] if entities.empty?

        entities.unshift @input.join
        @input.clear
        @input << entities.pop
        @input_size = @input.first.size if @size_limit
        entities
      end

      def flush
        buffer = @input.join
        @input.clear
        buffer
      end

      def empty?
        @input.empty?
      end
    end
  end
end