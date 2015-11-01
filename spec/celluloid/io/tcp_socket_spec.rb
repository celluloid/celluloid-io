require "spec_helper"

RSpec.describe Celluloid::IO::TCPSocket, library: :IO do
  let(:payload) { "ohai" }
  let(:example_port) { assign_port }
  let(:logger) { Specs::FakeLogger.current }

  context "inside Celluloid::IO" do
    describe ".open" do
      it "returns the open socket" do
        server = ::TCPServer.new example_addr, example_port
        thread = Thread.new { server.accept }

        socket = within_io_actor { Celluloid::IO::TCPSocket.open(example_addr, example_port) }
        expect(socket).to be_a(Celluloid::IO::TCPSocket)

        server.close
        thread.terminate
        socket.close
      end
      context "when passed a block" do
        it "returns the block evaluation" do
          server = ::TCPServer.new example_addr, example_port
          thread = Thread.new { server.accept }

          value = within_io_actor { Celluloid::IO::TCPSocket.open(example_addr, example_port) { true } }
          expect(value).to be_truthy

          server.close
          thread.terminate
        end
      end
    end

    it "connects to TCP servers" do
      server = ::TCPServer.new example_addr, example_port
      thread = Thread.new { server.accept }
      socket = within_io_actor { Celluloid::IO::TCPSocket.new example_addr, example_port }
      peer = thread.value

      peer << payload
      expect(within_io_actor { socket.read(payload.size) }).to eq payload

      server.close
      socket.close
      peer.close
    end

    it "should be evented" do
      with_connected_sockets(example_port) do |subject|
        expect(within_io_actor { Celluloid::IO.evented? }).to be_truthy
      end
    end

    it "read complete payload when nil size is given to #read" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(nil) }).to eq payload
      end
    end

    it "read complete payload when no size is given to #read" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read }).to eq payload
      end
    end

    it "reads data" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(payload.size) }).to eq payload
      end
    end

    it "reads data in binary encoding" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(payload.size).encoding }).to eq Encoding::BINARY
      end
    end

    it "reads partial data" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload * 2
        expect(within_io_actor { subject.readpartial(payload.size) }).to eq payload
      end
    end

    it "reads partial data in binary encoding" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload * 2
        expect(within_io_actor { subject.readpartial(payload.size).encoding }).to eq Encoding::BINARY
      end
    end

    it "writes data" do
      with_connected_sockets(example_port) do |subject, peer|
        within_io_actor { subject << payload }
        expect(peer.read(payload.size)).to eq payload
      end
    end

    it "raises Errno::ECONNREFUSED when the connection is refused" do
      allow(logger).to receive(:crash).with("Actor crashed!", Errno::ECONNREFUSED)
      expect do
        within_io_actor { ::TCPSocket.new(example_addr, example_port) }
      end.to raise_error(Errno::ECONNREFUSED)
    end

    context "eof?" do
      it "blocks actor then returns by close" do
        with_connected_sockets(example_port) do |subject, peer|
          started_at = Time.now
          Thread.new { sleep 0.5; peer.close; }
          within_io_actor { subject.eof? }
          expect(Time.now - started_at).to be > 0.5
        end
      end

      it "blocks until gets the next byte" do
        allow(logger).to receive(:crash).with("Actor crashed!", Celluloid::TaskTimeout)
        with_connected_sockets(example_port) do |subject, peer|
          peer << 0x00
          peer.flush
          expect do
            within_io_actor do
              subject.read(1)
              Celluloid.timeout(0.5) do
                expect(subject.eof?).to be_falsey
              end
            end
          end.to raise_error(Celluloid::TaskTimeout)
        end
      end
    end

    context "readpartial" do
      it "raises EOFError when reading from a closed socket" do
        allow(logger).to receive(:crash).with("Actor crashed!", EOFError)
        with_connected_sockets(example_port) do |subject, peer|
          peer.close
          expect do
            within_io_actor { subject.readpartial(payload.size) }
          end.to raise_error(EOFError)
        end
      end

      it "raises IOError when active sockets are closed across threads" do
        pending "not implemented"

        with_connected_sockets(example_port) do |subject, peer|
          actor = with_wrapper_actor
          allow(logger).to receive(:crash).with("Actor crashed!", IOError)
          begin
            read_future = actor.future.wrap do
              subject.readpartial(payload.size)
            end
            sleep 0.1
            subject.close
            expect { read_future.value 0.25 }.to raise_error(IOError)
          ensure
            actor.terminate if actor.alive?
          end
        end
      end

      it "raises IOError when partial reading from a socket the peer closed" do
        pending "async block running on receiver"
        with_connected_sockets(example_port) do |subject, peer|
          actor = with_wrapper_actor
          allow(logger).to receive(:crash).with("Actor crashed!", IOError)
          begin
            actor.async.wrap { sleep 0.01; peer.close }
            expect do
              within_io_actor { subject.readpartial(payload.size) }
            end.to raise_error(IOError)
          ensure
            actor.terminate if actor.alive?
          end
        end
      end
    end

    context "close" do

      it "flushes remaining data" do
        with_connected_sockets(example_port) do |subject, peer|
          subject.sync = false
          within_io_actor { subject << payload }
          expect{ peer.read_nonblock payload.length }.to raise_exception ::IO::WaitReadable
          within_io_actor { subject.close }
          expect(peer.read).to eq payload
        end
      end

    end
  end

  context "outside Celluloid::IO" do
    it "connects to TCP servers" do
      server = ::TCPServer.new example_addr, example_port
      thread = Thread.new { server.accept }
      socket = Celluloid::IO::TCPSocket.new example_addr, example_port
      peer = thread.value

      peer << payload
      expect(socket.read(payload.size)).to eq payload

      server.close
      socket.close
      peer.close
    end

    it "should be blocking" do
      with_connected_sockets(example_port) do |subject|
        expect(Celluloid::IO).not_to be_evented
      end
    end

    it "reads data" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload
        expect(subject.read(payload.size)).to eq payload
      end
    end

    it "reads partial data" do
      with_connected_sockets(example_port) do |subject, peer|
        peer << payload * 2
        expect(subject.readpartial(payload.size)).to eq payload
      end
    end

    it "writes data" do
      with_connected_sockets(example_port) do |subject, peer|
        subject << payload
        expect(peer.read(payload.size)).to eq payload
      end
    end
  end
end
