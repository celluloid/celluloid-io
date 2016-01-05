module Celluloid
  module IO
    # Base class for all classes that wrap a ruby socket.
    # @abstract
    class Socket
      extend Forwardable

      def_delegators :@socket, :close, :close_read, :close_write, :closed?
      def_delegators :@socket, :read_nonblock, :write_nonblock
      def_delegators :@socket, :addr, :getsockopt, :setsockopt, :getsockname, :fcntl

      # @param socket [BasicSocket, OpenSSL::SSL::SSLSocket]
      def initialize(socket)
        case socket
        when ::BasicSocket, OpenSSL::SSL::SSLSocket
          @socket = socket
        else
          raise ArgumentError, "expected a socket, got #{socket.inspect}"
        end
      end

      # Returns the wrapped socket.
      # @return [BasicSocket, OpenSSL::SSL::SSLSocket]
      def to_io
        @socket
      end

      # Compatibility
      Constants = ::Socket::Constants
      include Constants

      # Celluloid::IO:Socket.new behaves like Socket.new for compatibility.
      # This is is not problematic since Celluloid::IO::Socket is abstract.
      # To instantiate a socket use one of its subclasses.
      def self.new(*args)
        if self == Celluloid::IO::Socket
          return ::Socket.new(*args)
        else
          super
        end
      end

      # Tries to convert the given ruby socket into a subclass of GenericSocket.
      # @param socket
      # @return [SSLSocket, TCPServer, TCPSocket, UDPSocket, UNIXServer, UNIXSocket]
      # @return [nil] if the socket can't be converted
      def self.try_convert(socket, convert_io = true)
        case socket
        when Celluloid::IO::Socket, Celluloid::IO::SSLServer
          socket
        when ::TCPServer
          TCPServer.new(socket)
        when ::TCPSocket
          TCPSocket.new(socket)
        when ::UDPSocket
          UDPSocket.new(socket)
        when ::UNIXServer
          UNIXServer.new(socket)
        when ::UNIXSocket
          UNIXSocket.new(socket)
        when OpenSSL::SSL::SSLServer
          SSLServer.new(socket.to_io, socket.instance_variable_get(:@ctx))
        when OpenSSL::SSL::SSLSocket
          SSLSocket.new(socket)
        else
          if convert_io
            return try_convert(IO.try_convert(socket), false)
          end
          nil
        end
      end

      class << self
        extend Forwardable
        def_delegators '::Socket', *(::Socket.methods - self.methods - [:try_convert])
      end

    end
  end
end
