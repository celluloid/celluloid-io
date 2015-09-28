require "spec_helper"
require "openssl"

RSpec.describe Celluloid::IO::SSLSocket, library: :IO do
  let(:request)  { "ping" }
  let(:response) { "pong" }

  let(:example_port) { assign_port }
  let(:client_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("client.crt").read }
  let(:client_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("client.key").read }
  let(:client_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = client_cert
      context.key  = client_key
    end
  end

  after(:each) do
    client.close rescue nil
    server.close rescue nil
  end

  let(:client) do
    attempts = 0
    socket = begin
      Timeout.timeout(Specs::MAX_EXECUTION) do
        begin
          TCPSocket.new example_addr, example_port
        rescue Errno::ECONNREFUSED
          raise if attempts >= Specs::MAX_ATTEMPTS
          attempts += 1
          # HAX: sometimes this fails to connect? o_O
          # ... This can often fail 20 times in a row ... so yeah
          # This is quite likely due to the Thread.pass style spinlocks for startup
          # Seems gimpy, but sleep and retry
          sleep 0.0126
          retry
        end
      end
    rescue => ex
      attempted = "Tried #{attempts} times to instantiate socket."
      raise ex.class.new(attempted)
    end
    return socket
  end

  let(:ssl_client) { Celluloid::IO::SSLSocket.new client, client_context }

  let(:server_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("server.crt").read }
  let(:server_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("server.key").read }
  let(:server_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = server_cert
      context.key  = server_key
    end
  end

  let(:server)     { TCPServer.new example_addr, example_port }
  let(:ssl_server) { OpenSSL::SSL::SSLServer.new(server, server_context) }
  let(:server_thread) do
    server = Thread.new { ssl_server.accept }.tap do |thread|
      Thread.pass while thread.status && thread.status != "sleep"
      thread.join unless thread.status
    end
    server
  end

  let(:celluloid_server) { Celluloid::IO::TCPServer.new example_addr, example_port }
  let(:raw_server_thread) do
    server = Thread.new { celluloid_server.accept }.tap do |thread|
      Thread.pass while thread.status && thread.status != "sleep"
      thread.join unless thread.status
    end
    server
  end

  context "duck typing ::SSLSocket" do
    it "responds to #peeraddr" do
      with_ssl_sockets do |ssl_client, ssl_peer|
        expect { ssl_client.peeraddr }.to_not raise_error
      end
    end
  end

  context "inside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      with_ssl_sockets do |ssl_client, ssl_peer|
        within_io_actor do
          ssl_peer << request
          expect(ssl_client.read(request.size)).to eq(request)

          ssl_client << response
          expect(ssl_peer.read(response.size)).to eq(response)
        end
      end
    end

    it "starts SSL on a connected TCP socket" do
      if RUBY_PLATFORM == "java"
        pending "JRuby support"
        fail "Bypassing potential deadlock."
      end
      with_raw_sockets do |client, peer|
        within_io_actor do
          peer << request
          expect(client.read(request.size)).to eq(request)

          client << response
          expect(peer.read(response.size)).to eq(response)

          # now that we've written bytes, upgrade to SSL
          client_thread = Thread.new { OpenSSL::SSL::SSLSocket.new(client).connect }
          ssl_peer = Celluloid::IO::SSLSocket.new peer, server_context
          expect(ssl_peer).to eq(ssl_peer.accept)
          ssl_client = client_thread.value

          ssl_peer << request
          expect(ssl_client.read(request.size)).to eq(request)

          ssl_client << response
          expect(ssl_peer.read(response.size)).to eq(response)
        end
      end
    end
  end

  context "outside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      with_ssl_sockets do |ssl_client, ssl_peer|
        ssl_peer << request
        expect(ssl_client.read(request.size)).to eq(request)

        ssl_client << response
        expect(ssl_peer.read(response.size)).to eq(response)
      end
    end

    it "starts SSL on a connected TCP socket" do
      if RUBY_PLATFORM == "java"
        pending "JRuby support"
        fail "Bypassing potential deadlock."
      end
      with_raw_sockets do |client, peer|
        peer << request
        expect(client.read(request.size)).to eq(request)

        client << response
        expect(peer.read(response.size)).to eq(response)

        # now that we've written bytes, upgrade to SSL
        client_thread = Thread.new { OpenSSL::SSL::SSLSocket.new(client).connect }
        ssl_peer = Celluloid::IO::SSLSocket.new peer, server_context
        expect(ssl_peer).to eq(ssl_peer.accept)
        ssl_client = client_thread.value

        ssl_peer << request
        expect(ssl_client.read(request.size)).to eq(request)

        ssl_client << response
        expect(ssl_peer.read(response.size)).to eq(response)
      end
    end
  end

  it "knows its cert" do
    # FIXME: seems bad? o_O
    pending "wtf is wrong with this on JRuby" if RUBY_PLATFORM == "java"
    with_ssl_sockets do |ssl_client|
      expect(ssl_client.cert.to_der).to eq(client_cert.to_der)
    end
  end

  it "knows its peer_cert" do
    with_ssl_sockets do |ssl_client|
      expect(ssl_client.peer_cert.to_der).to eq(ssl_client.to_io.peer_cert.to_der)
    end
  end

  it "knows its peer_cert_chain" do
    with_ssl_sockets do |ssl_client|
      expect(ssl_client.peer_cert_chain.zip(ssl_client.to_io.peer_cert_chain).map do |c1, c2|
        c1.to_der == c2.to_der
      end).to be_all
    end
  end

  it "knows its cipher" do
    with_ssl_sockets do |ssl_client|
      expect(ssl_client.cipher).to eq(ssl_client.to_io.cipher)
    end
  end

  it "knows its client_ca" do
    # jruby-openssl does not implement this method
    pending "jruby-openssl support" if RUBY_PLATFORM == "java"

    with_ssl_sockets do |ssl_client|
      expect(ssl_client.client_ca).to eq(ssl_client.to_io.client_ca)
    end
  end

  it "verifies peer certificates" do
    # FIXME: JRuby seems to be giving the wrong result here o_O
    pending "jruby-openssl support" if RUBY_PLATFORM == "java"

    with_ssl_sockets do |ssl_client, ssl_peer|
      expect(ssl_client.verify_result).to eq(OpenSSL::X509::V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT)
    end
  end

  def with_ssl_sockets
    server_thread
    sleep 0.222 # Needs time to spin up, or will throw out Errno::ECONNECTREFUSED to client.
    ssl_client.connect

    begin
      ssl_peer = server_thread.value
      yield ssl_client, ssl_peer
    ensure
      server_thread.join
      ssl_server.close
      ssl_client.close
      ssl_peer.close
    end
  end

  def with_raw_sockets
    raw_server_thread
    sleep 0.222 # Needs time to spin up, or will throw out Errno::ECONNECTREFUSED to client.
    client

    begin
      peer = raw_server_thread.value
      yield client, peer
    ensure
      raw_server_thread.join
      celluloid_server.close
      client.close
      peer.close
    end
  end
end
