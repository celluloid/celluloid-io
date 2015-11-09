require "socket"

module Celluloid
  module IO
    # SSLServer wraps a TCPServer to provide immediate SSL accept
    class SSLServer
      extend Forwardable
      def_delegators :@tcp_server, :listen, :shutdown, :close, :closed?, :to_io

      attr_accessor :start_immediately
      attr_reader :tcp_server

      def initialize(server, ctx)
        @tcp_server = Socket.try_convert(server)
        @ctx = ctx
        @start_immediately = true
      end

      def accept
        sock = @tcp_server.accept
        begin
          ssl = Celluloid::IO::SSLSocket.new(sock, @ctx)
          ssl.accept if @start_immediately
          ssl
        rescue OpenSSL::SSL::SSLError
          sock.close
          raise
        end
      end
    end
  end
end
