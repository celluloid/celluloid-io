require "spec_helper"

RSpec.describe Celluloid::IO::Reactor, library: :IO do
  let(:payload) { "balls" }
  let(:example_port) { assign_port }

  it "shouldn't crash" do
    server = ::TCPServer.new example_addr, example_port

    thread = Thread.new { server.accept }

    socket = within_io_actor { Celluloid::IO::TCPSocket.new example_addr, example_port }
    peer = thread.value
    peer_thread = Thread.new { loop { peer << payload } }
    handle = false

    # Main server body:
    within_io_actor do
      begin
        timeout(2) do
          loop do
            socket.readpartial(2046)
          end
        end
      # rescuing timeout, ok. rescuing terminated exception, is it ok? TODO: investigate
      rescue Celluloid::TaskTerminated, Celluloid::TaskTimeout, Timeout::Error
      ensure
        socket.readpartial(2046)
        handle = true
      end
    end

    expect(handle).to be_truthy

    server.close
    peer.close
    socket.close
  end
end
