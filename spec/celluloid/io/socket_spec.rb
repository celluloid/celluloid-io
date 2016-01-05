require "spec_helper"

RSpec.describe Celluloid::IO::Socket, library: :IO do
  let(:logger) { Specs::FakeLogger.current }
  let(:example_port) { assign_port }

  context '.try_convert' do

    subject{ described_class.try_convert(socket) }

    after(:each) do
      if subject.respond_to? :close
        subject.close
      else
        socket.close if socket.respond_to? :close
      end
    end

    context 'with a Celluloid Socket' do
      let(:socket){ Celluloid::IO::UDPSocket.new }

      it 'returns given socket' do
        expect(subject).to be socket
      end
    end

    context 'with a ::TCPServer' do
      let(:socket){ ::TCPServer.new(example_port) }

      it 'creates a Celluloid::IO::TCPServer' do
        expect(subject).to be_a Celluloid::IO::TCPServer
      end
    end

    context 'with a ::TCPSocket' do
      let!(:server){
        ::TCPServer.new example_addr, example_port
      }
      after(:each){
        server.close
      }

      let(:socket){
        ::TCPSocket.new example_addr, example_port
      }

      it 'creates a Celluloid::IO::TCPSocket' do
        expect(subject).to be_a Celluloid::IO::TCPSocket
      end
    end

    context 'with a ::UDPSocket' do
      let(:socket){ ::UDPSocket.new }

      it 'creates a Celluloid::IO::UDPServer' do
        expect(subject).to be_a Celluloid::IO::UDPSocket
      end
    end

    context 'with a ::UNIXServer' do
      let(:socket){ ::UNIXServer.new(example_unix_sock) }

      it 'creates a Celluloid::IO::UNIXServer' do
        expect(subject).to be_a Celluloid::IO::UNIXServer
      end
    end

    context 'with a ::UNIXSocket' do
      let!(:server){
        ::UNIXServer.new(example_unix_sock)
      }
      after(:each){
        server.close
      }

      let(:socket){
        ::UNIXSocket.new example_unix_sock
      }

      it 'creates a Celluloid::IO::UNIXSocket' do
        expect(subject).to be_a Celluloid::IO::UNIXSocket
      end
    end

    context 'with an OpenSSL::SSL::SSLServer' do
      let(:socket){
        OpenSSL::SSL::SSLServer.new(::TCPServer.new(example_addr, example_port), OpenSSL::SSL::SSLContext.new)
      }

      it 'creates a Celluloid::IO::SSLServer' do
        expect(subject).to be_a Celluloid::IO::SSLServer
      end
    end

    context 'with an OpenSSL::SSL::SSLSocket' do
      let!(:server){
        OpenSSL::SSL::SSLServer.new(::TCPServer.new(example_addr, example_port), OpenSSL::SSL::SSLContext.new)
      }
      after(:each){
        server.close
      }

      let(:socket){
        OpenSSL::SSL::SSLSocket.new(::TCPSocket.new(example_addr, example_port))
      }

     it 'creates a Celluloid::IO::SSLSocket' do
        expect(subject).to be_a Celluloid::IO::SSLSocket
      end
    end

    context 'with an object responding to #to_io' do
      let(:real){
        ::UDPSocket.new
      }

      let(:socket){
        proxy = double(:socket)
        allow(proxy).to receive(:to_io){ real }
        allow(proxy).to receive(:close){ real.close }
        proxy
      }

      it 'creates a celluloid socket' do
        expect(subject).to be_a described_class
      end

      it 'uses the returned IO' do
        expect(subject.to_io).to be socket.to_io
      end
    end

    context 'with a simple object' do
      let(:socket){ Object.new }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  context 'compatibility with ::Socket' do

    context '.new' do
      it "creates basic sockets" do
        socket = Celluloid::IO::Socket.new(Celluloid::IO::Socket::AF_INET, Celluloid::IO::Socket::SOCK_STREAM, 0)
        expect(socket).to be_a ::Socket
        socket.close
      end
    end

    context '.pair' do
      it "creates basic sockets" do
        a,b = Celluloid::IO::Socket.pair( Celluloid::IO::Socket::AF_UNIX, Celluloid::IO::Socket::SOCK_DGRAM, 0)
        expect(a).to be_a ::Socket
        expect(b).to be_a ::Socket
        a.close
        b.close
      end
    end

    context '.for_fd' do
      it "creates basic sockets" do
        socket = Celluloid::IO::Socket.new(Celluloid::IO::Socket::AF_INET, Celluloid::IO::Socket::SOCK_STREAM, 0)
        copy = Celluloid::IO::Socket.for_fd(socket.fileno)
        expect(copy).to be_a ::Socket
        copy.close
      end
    end

  end

end
