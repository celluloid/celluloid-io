require "spec_helper"

RSpec.describe Celluloid::IO::SSLServer, library: :IO do
  let(:client_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("client.crt").read }
  let(:client_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("client.key").read }
  let(:client_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = client_cert
      context.key  = client_key
    end
  end

  let(:example_port) { assign_port }
  let(:server_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("server.crt").read }
  let(:server_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("server.key").read }
  let(:server_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = server_cert
      context.key  = server_key
    end
  end

  describe "#accept" do
    let(:payload) { "ohai" }

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_ssl_server(example_port) do |subject|
          expect(within_io_actor { Celluloid::IO.evented? }).to be_truthy
        end
      end

      it "accepts a connection and returns a Celluloid::IO::SSLSocket" do
        with_ssl_server(example_port) do |subject|
          thread = Thread.new do
            raw = TCPSocket.new(example_addr, example_port)
            OpenSSL::SSL::SSLSocket.new(raw, client_context).connect
          end
          peer = within_io_actor { subject.accept }
          expect(peer).to be_a Celluloid::IO::SSLSocket

          client = thread.value
          client.write payload
          expect(peer.read(payload.size)).to eq payload
        end
      end
    end

    context "outside Celluloid::IO" do
      it "should be blocking" do
        with_ssl_server(example_port) do |subject|
          expect(Celluloid::IO).not_to be_evented
        end
      end

      it "accepts a connection and returns a Celluloid::IO::SSLSocket" do
        with_ssl_server(example_port) do |subject|
          thread = Thread.new do
            raw = TCPSocket.new(example_addr, example_port)
            OpenSSL::SSL::SSLSocket.new(raw, client_context).connect
          end
          peer = subject.accept
          expect(peer).to be_a Celluloid::IO::SSLSocket

          client = thread.value
          client.write payload
          expect(peer.read(payload.size)).to eq payload
        end
      end
    end
  end

  describe "#initialize" do
    it "should auto-wrap a raw ::TCPServer" do
      raw_server = ::TCPServer.new(example_addr, example_port)
      with_ssl_server(example_port, raw_server) do |ssl_server|
        expect(ssl_server.tcp_server.class).to eq(Celluloid::IO::TCPServer)
      end
    end
  end

  def with_ssl_server(port, raw_server = nil)
    raw_server ||= Celluloid::IO::TCPServer.new(example_addr, port)
    server = Celluloid::IO::SSLServer.new(raw_server, server_context)
    begin
      yield server
    ensure
      server.close
    end
  end
end
