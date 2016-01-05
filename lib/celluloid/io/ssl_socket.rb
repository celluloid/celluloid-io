require "openssl"

module Celluloid
  module IO
    # SSLSocket with Celluloid::IO support
    class SSLSocket < Stream
      extend Forwardable

      def_delegators :to_io,
                     :cert,
                     :cipher,
                     :client_ca,
                     :peeraddr,
                     :peer_cert,
                     :peer_cert_chain,
                     :post_connection_check,
                     :verify_result,
                     :sync_close=

      def initialize(io, ctx = OpenSSL::SSL::SSLContext.new)
        @context = ctx
        socket = OpenSSL::SSL::SSLSocket.new(::IO.try_convert(io), @context)
        socket.sync_close = true if socket.respond_to?(:sync_close=)
        super(socket)
      end

      def connect
        to_io.connect_nonblock
        self
      rescue ::IO::WaitReadable
        wait_readable
        retry
      end

      def accept
        to_io.accept_nonblock
        self
      rescue ::IO::WaitReadable
        wait_readable
        retry
      rescue ::IO::WaitWritable
        wait_writable
        retry
      end

    end
  end
end
