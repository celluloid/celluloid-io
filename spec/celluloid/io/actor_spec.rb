require "spec_helper"

RSpec.describe Celluloid::IO, library: :IO do
  it_behaves_like "a Celluloid Actor", Celluloid::IO do
    let(:example_port) { assign_port }

    context :timeouts do
      let :sleeping_actor_class do
        Class.new do
          include Celluloid::IO
          def initialize(addr, port)
            @server = Celluloid::IO::TCPServer.new(addr, port)
            async { @server.accept ; sleep 10 }
          end
        end
      end
      let :foo_actor_class do
        Class.new do
          include Celluloid::IO
          def initialize(addr, port)
            @sock = Celluloid::IO::TCPSocket.new(addr, port)
          end

          # returns true if the operation timedout
          def timedout_read(duration)
            begin 
              timeout(duration) do
                @sock.wait_readable
              end
            rescue Celluloid::TaskTimeout
              return true
            end
            false
          end
 
          # returns true if it cannot write (socket is already registered)
          def failed_write
            begin
              @sock.wait_readable
            rescue ArgumentError # IO Selector Exception
              return true
            end
            false
          end
        end
      end

      it "frees up the socket when a timeout error occurs" do
        a1 = sleeping_actor_class.new(example_addr, example_port)
        a2 = foo_actor_class.new(example_addr, example_port)
      
        expect(a2.timedout_read(1)).to eq true # this ensures that the socket timeouted trying to read
        skip "not implemented"
        expect(a2.failed_write).to eq false # this ensures that the socket isn't usable anymore
      end
    end
  end
end
