require 'socket'

module Celluloid
  module IO
    # TCPServer with combined blocking and evented support
    class TCPServer < Socket
      extend Forwardable
      def_delegators :to_io, :listen, :sysaccept, :addr

      # @overload initialize(port)
      #   Opens a tcp server on the given port.
      #   @param port [Numeric]
      #
      # @overload initialize(hostname, port)
      #   Opens a tcp server on the given port and interface.
      #   @param hostname [String]
      #   @param port [Numeric]
      #
      # @overload initialize(socket)
      #   Wraps an already existing tcp server instance.
      #   @param socket [::TCPServer]
      def initialize(*args)
        if args.first.kind_of? ::BasicSocket
          # socket
          socket = args.first
          fail ArgumentError, "wrong number of arguments (#{args.size} for 1)" if args.size != 1
          fail ArgumentError, "wrong kind of socket (#{socket.class} for TCPServer)" unless socket.kind_of? ::TCPServer
          super(socket)
        else
          super(::TCPServer.new(*args))
        end
      end

      # @return [TCPSocket]
      def accept
        Celluloid::IO.wait_readable(to_io)
        accept_nonblock
      end

      # @return [TCPSocket]
      def accept_nonblock
        Celluloid::IO::TCPSocket.new(to_io.accept_nonblock)
      end

      # Convert a Ruby TCPServer into a Celluloid::IO::TCPServer
      # @deprecated Use .new instead.
      def self.from_ruby_server(ruby_server)
        warn "#from_ruby_server is deprecated please use .new instead"
        
        self.new(ruby_server)
      end
    end
  end
end
