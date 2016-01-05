require 'socket'

module Celluloid
  module IO
    # UNIXServer with combined blocking and evented support
    class UNIXServer < Socket
      extend Forwardable
      def_delegators :to_io, :listen, :sysaccept

      def self.open(socket_path)
        self.new(socket_path)
      end

      # @overload initialize(socket_path)
      #   @param socket_path [String]
      #
      # @overload initialize(socket)
      #   @param socket [::UNIXServer]
      def initialize(socket)
        if socket.kind_of? ::BasicSocket
          # socket
          fail ArgumentError, "wrong kind of socket (#{socket.class} for UNIXServer)" unless socket.kind_of? ::UNIXServer
          super(socket)
        else
          begin
            super(::UNIXServer.new(socket))
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
      end

      def accept
        Celluloid::IO.wait_readable(to_io)
        accept_nonblock
      end

      def accept_nonblock
        Celluloid::IO::UNIXSocket.new(to_io.accept_nonblock)
      end

    end
  end
end
