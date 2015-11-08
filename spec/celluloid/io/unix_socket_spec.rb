require "spec_helper"

RSpec.describe Celluloid::IO::UNIXSocket, library: :IO do
  if RUBY_PLATFORM == "java"
    before(:each) do
      pending "jRuby support"
      fail "Avoid potential deadlock under jRuby"
    end
  end

  let(:payload) { "ohai" }
  let(:example_port) { assign_port }
  let(:logger) { Specs::FakeLogger.current }

  context "inside Celluloid::IO" do
    it "connects to UNIX servers" do
      server = ::UNIXServer.open example_unix_sock
      thread = Thread.new { server.accept }
      socket = within_io_actor { Celluloid::IO::UNIXSocket.open example_unix_sock }
      peer = thread.value

      peer << payload
      expect(within_io_actor { socket.read(payload.size) }).to eq payload

      server.close
      socket.close
      peer.close
      File.delete(example_unix_sock)
    end

    it "should be evented" do
      with_connected_unix_sockets do |subject|
        expect(within_io_actor { Celluloid::IO.evented? }).to be_truthy
      end
    end

    it "read complete payload when nil size is given to #read" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(nil) }).to eq payload
      end
    end

    it "read complete payload when no size is given to #read" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read }).to eq payload
      end
    end

    it "reads data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(payload.size) }).to eq payload
      end
    end

    it "reads data in binary encoding" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        expect(within_io_actor { subject.read(payload.size).encoding }).to eq Encoding::BINARY
      end
    end

    it "reads partial data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        expect(within_io_actor { subject.readpartial(payload.size) }).to eq payload
      end
    end

    it "reads partial data in binary encoding" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        expect(within_io_actor { subject.readpartial(payload.size).encoding }).to eq Encoding::BINARY
      end
    end

    it "writes data" do
      with_connected_unix_sockets do |subject, peer|
        within_io_actor { subject << payload }
        expect(peer.read(payload.size)).to eq payload
      end
    end

    it "raises Errno::ENOENT when the connection is refused" do
      allow(logger).to receive(:crash).with("Actor crashed!", Errno::ENOENT)
      expect do
        within_io_actor { Celluloid::IO::UNIXSocket.open(example_unix_sock) }
      end.to raise_error(Errno::ENOENT)
    end

    it "raises EOFError when partial reading from a closed socket" do
      allow(logger).to receive(:crash).with("Actor crashed!", EOFError)
      with_connected_unix_sockets do |subject, peer|
        peer.close
        expect do
          within_io_actor { subject.readpartial(payload.size) }
        end.to raise_error(EOFError)
      end
    end

    context "eof?" do
      it "blocks actor then returns by close" do
        with_connected_unix_sockets do |subject, peer|
          started_at = Time.now
          Thread.new { sleep 0.5; peer.close; }
          within_io_actor { subject.eof? }
          expect(Time.now - started_at).to be > 0.5
        end
      end

      it "blocks until gets the next byte" do
        allow(logger).to receive(:crash).with("Actor crashed!", Celluloid::TaskTimeout)
        with_connected_unix_sockets do |subject, peer|
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
  end

  context "outside Celluloid::IO" do
    it "connects to UNIX servers" do
      server = ::UNIXServer.new example_unix_sock
      thread = Thread.new { server.accept }
      socket = Celluloid::IO::UNIXSocket.open example_unix_sock
      peer = thread.value

      peer << payload
      expect(socket.read(payload.size)).to eq payload

      server.close
      socket.close
      peer.close
      File.delete example_unix_sock
    end

    it "should be blocking" do
      with_connected_unix_sockets do |subject|
        expect(Celluloid::IO).not_to be_evented
      end
    end

    it "reads data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        expect(subject.read(payload.size)).to eq payload
      end
    end

    it "reads partial data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        expect(subject.readpartial(payload.size)).to eq payload
      end
    end

    it "writes data" do
      with_connected_unix_sockets do |subject, peer|
        subject << payload
        expect(peer.read(payload.size)).to eq payload
      end
    end
  end

  context 'puts' do
    it 'uses the write buffer' do
      with_connected_unix_sockets do |subject, peer|
        subject.sync = false
        subject << "a"
        subject.puts "b"
        subject << "c"
        subject.flush
        subject.close
        expect(peer.read).to eq "ab\nc"
      end
    end
  end

  context 'readline' do
    it 'uses the read buffer' do
      with_connected_unix_sockets do |subject, peer|
        peer << "xline one\nline two\n"
        subject.getc # read one character to fill buffer
        Timeout::timeout(1){
          # this will block if the buffer is not used
          expect(subject.readline).to eq "line one\n"
          expect(subject.readline).to eq "line two\n"
        }
      end
    end
  end

end
