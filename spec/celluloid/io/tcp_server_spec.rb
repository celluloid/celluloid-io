require 'spec_helper'

describe Celluloid::IO::TCPServer do
  describe "#accept" do
    let(:payload) { 'ohai' }

    it "can be initialized without a host" do
      expect{ server = Celluloid::IO::TCPServer.new(2000); server.close }.to_not raise_error
    end

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_tcp_server do |subject|
          within_io_actor { Celluloid::IO.evented? }.should be_true
        end
      end

      it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
        with_tcp_server do |subject|
          thread = Thread.new { TCPSocket.new(example_addr, example_port) }
          peer = within_io_actor { subject.accept }
          peer.should be_a Celluloid::IO::TCPSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end

      it "sends information to the client later" do
        class LaterActor < ExampleActor
          def send_later(socket)
            peer = socket.accept
            after(0.4) { peer.write "1" }
            after(0.4) { peer.write "2" }
            peer
          end
        end
        with_tcp_server do |subject|
          thread = Thread.new { TCPSocket.new(example_addr, example_port) }
          actor = LaterActor.new
          begin
            peer = actor.send_later(subject)
            client = thread.value
            client.write payload
            peer.read(payload.size).should eq payload # confirm the client read
            Timeout::timeout(1) { client.read(4).should eq "1" }
            Timeout::timeout(2) { client.read(4).should eq "2" }
          ensure
            actor.terminate if actor.alive?
          end
        end
      end

      context "outside Celluloid::IO" do
        it "should be blocking" do
          with_tcp_server do |subject|
            Celluloid::IO.should_not be_evented
          end
        end

        it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
          with_tcp_server do |subject|
            thread = Thread.new { TCPSocket.new(example_addr, example_port) }
            peer   = subject.accept
            peer.should be_a Celluloid::IO::TCPSocket

            client = thread.value
            client.write payload
            peer.read(payload.size).should eq payload
          end
        end
      end
    end
  end
end
