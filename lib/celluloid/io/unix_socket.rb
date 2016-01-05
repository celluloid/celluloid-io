require "socket"

module Celluloid
  module IO
    # UNIXSocket with combined blocking and evented support
    class UNIXSocket < Stream
      # Open a UNIX connection.
      def self.open(socket_path, &block)
        new(socket_path, &block)
      end

      # Convert a Ruby UNIXSocket into a Celluloid::IO::UNIXSocket
      # DEPRECATED: to be removed in a future release
      # @deprecated use .new instead
      def self.from_ruby_socket(ruby_socket)
        new(ruby_socket)
      end

      # Open a UNIX connection.
      def initialize(socket_path, &block)
        # Allow users to pass in a Ruby UNIXSocket directly
        if socket_path.is_a? ::UNIXSocket
          super(socket_path)
          return
        end

        # FIXME: not doing non-blocking connect
        if block
          super ::UNIXSocket.open(socket_path, &block)
        else
          super ::UNIXSocket.new(socket_path)
        end
      end

    end
  end
end
