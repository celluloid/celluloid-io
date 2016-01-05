module Celluloid
  module IO
    # UDPSockets with combined blocking and evented support
    class UDPSocket < Socket
      extend Forwardable
      def_delegators :to_io, :bind, :connect, :send, :recvfrom_nonblock

      # @overload initialize(address_family)
      #   Opens a new udp socket using address_family.
      #   @param address_family [Numeric]
      #
      # @overload initialize(socket)
      #   Wraps an already existing udp socket.
      #   @param socket [::UDPSocket]
      def initialize(*args)
        if args.first.kind_of? ::BasicSocket
          # socket
          socket = args.first
          fail ArgumentError, "wrong number of arguments (#{args.size} for 1)" if args.size != 1
          fail ArgumentError, "wrong kind of socket (#{socket.class} for UDPSocket)" unless socket.kind_of? ::UDPSocket
          super(socket)
        else
          super(::UDPSocket.new(*args))
        end
      end

      # Wait until the socket is readable
      def wait_readable; Celluloid::IO.wait_readable(self); end

      # Receives up to maxlen bytes from socket. flags is zero or more of the
      # MSG_ options. The first element of the results, mesg, is the data
      # received. The second element, sender_addrinfo, contains
      # protocol-specific address information of the sender.
      def recvfrom(maxlen, flags = 0)
        begin
          socket = to_io
          if socket.respond_to? :recvfrom_nonblock
            socket.recvfrom_nonblock(maxlen, flags)
          else
            # FIXME: hax for JRuby
            socket.recvfrom(maxlen, flags)
          end
        rescue ::IO::WaitReadable
          wait_readable
          retry
        end
      end

    end
  end
end
