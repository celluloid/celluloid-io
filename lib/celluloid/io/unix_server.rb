require 'socket'

module Celluloid
  module IO
    # UNIXServer with combined blocking and evented support
    class UNIXServer
      extend Forwardable
      def_delegators :@server, :listen, :sysaccept, :close, :closed?

      def self.open(socket_path)
        self.new(socket_path)
      end

      def initialize(socket_path)
        begin
          @server = ::UNIXServer.new(socket_path)
        rescue => ex
          # Translate the EADDRINUSE jRuby exception.
          raise unless RUBY_PLATFORM == 'java'
          if ex.class.name == "IOError" && # Won't agree to .is_a?(IOError)
             ex.message.include?("in use")
            raise Errno::EADDRINUSE.new(ex.message)
          end
          raise
        end
      end

      def accept
        Celluloid::IO.wait_readable(@server)
        accept_nonblock
      end

      def accept_nonblock
        Celluloid::IO::UNIXSocket.new(@server.accept_nonblock)
      end

      def to_io
        @server
      end
    end
  end
end
