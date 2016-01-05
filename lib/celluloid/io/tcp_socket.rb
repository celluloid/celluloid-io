require "socket"
require "resolv"

module Celluloid
  module IO
    # TCPSocket with combined blocking and evented support
    class TCPSocket < Stream
      extend Forwardable

      def_delegators :to_io, :peeraddr

      # Open a TCP socket, yielding it to the given block and closing it
      # automatically when done (if a block is given)
      def self.open(*args, &_block)
        sock = new(*args)
        return sock unless block_given?

        begin
          yield(sock)
        ensure
          sock.close
        end
      end

      # Convert a Ruby TCPSocket into a Celluloid::IO::TCPSocket
      # DEPRECATED: to be removed in a future release
      # @deprecated Use {Celluloid::IO::TCPSocket#new} instead.
      def self.from_ruby_socket(ruby_socket)
        new(ruby_socket)
      end

      # @overload initialize(remote_host, remote_port = nil, local_host = nil, local_port = nil)
      #   Opens a TCP connection to remote_host on remote_port. If local_host
      #   and local_port are specified, then those parameters are used on the
      #   local end to establish the connection.
      #   @param remote_host [String, Resolv::IPv4, Resolv::IPv6]
      #   @param remote_port [Numeric]
      #   @param local_host  [String]
      #   @param local_port  [Numeric]
      #
      # @overload initialize(socket)
      #   Wraps an already existing tcp socket.
      #   @param socket [::TCPSocket]
      #
      def initialize(*args)
        if args.first.kind_of? ::BasicSocket
          # socket
          socket = args.first
          fail ArgumentError, "wrong number of arguments (#{args.size} for 1)" if args.size != 1
          fail ArgumentError, "wrong kind of socket (#{socket.class} for TCPSocket)" unless socket.kind_of? ::TCPSocket
          super(socket)
        else
          super(create_socket(*args))
        end
      end

      # Receives a message
      def recv(maxlen, flags = nil)
        fail NotImplementedError, "flags not supported" if flags && !flags.zero?
        readpartial(maxlen)
      end

      # Send a message
      def send(msg, flags, dest_sockaddr = nil)
        fail NotImplementedError, "dest_sockaddr not supported" if dest_sockaddr
        fail NotImplementedError, "flags not supported" unless flags.zero?
        write(msg)
      end

      # @return [Resolv::IPv4, Resolv::IPv6]
      def addr
        socket = to_io
        ra = socket.remote_address
        if ra.ipv4?
          return Resolv::IPv4.create(ra.ip_address)
        elsif ra.ipv6?
          return Resolv::IPv6.create(ra.ip_address)
        else
          raise ArgumentError, "not an ip socket: #{socket.inspect}"
        end
      end
    private

      def create_socket(remote_host, remote_port = nil, local_host = nil, local_port = nil)
        # Is it an IPv4 address?
        begin
          addr = Resolv::IPv4.create(remote_host)
        rescue ArgumentError
        end

        # Guess it's not IPv4! Is it IPv6?
        unless addr
          begin
            addr = Resolv::IPv6.create(remote_host)
          rescue ArgumentError
          end
        end

        # Guess it's not an IP address, so let's try DNS
        unless addr
          addrs = Array(DNSResolver.new.resolve(remote_host))
          fail Resolv::ResolvError, "DNS result has no information for #{remote_host}" if addrs.empty?

          # Pseudorandom round-robin DNS support :/
          addr = addrs[rand(addrs.size)]
        end

        case addr
        when Resolv::IPv4
          family = Socket::AF_INET
        when Resolv::IPv6
          family = Socket::AF_INET6
        else fail ArgumentError, "unsupported address class: #{addr.class}"
        end

        socket = Socket.new(family, Socket::SOCK_STREAM, 0)
        socket.bind Addrinfo.tcp(local_host, local_port) if local_host

        begin
          socket.connect_nonblock Socket.sockaddr_in(remote_port, addr.to_s)
        rescue Errno::EINPROGRESS, Errno::EALREADY
          # JRuby raises EINPROGRESS, MRI raises EALREADY
          Celluloid::IO.wait_writable(socket)

          # HAX: for some reason we need to finish_connect ourselves on JRuby
          # This logic is unnecessary but JRuby still throws Errno::EINPROGRESS
          # if we retry the non-blocking connect instead of just finishing it
          retry unless RUBY_PLATFORM == "java" && socket.to_channel.finish_connect
        rescue Errno::EISCONN
          # We're now connected! Yay exceptions for flow control
          # NOTE: This is the approach the Ruby stdlib docs suggest ;_;
        end

        return socket
      end
    end
  end
end
