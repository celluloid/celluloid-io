require "spec_helper"

RSpec.describe Celluloid::IO::DNSResolver, library: :IO do
  context '#resolve' do
    it "resolves hostnames statically from hosts file without nameservers" do
      # /etc/resolv.conf doesn't exist on Mac OSX when no networking is
      # disabled, thus .nameservers would return nil
      expect(Celluloid::IO::DNSResolver).to receive(:nameservers).at_most(:once) { nil }
      resolver = Celluloid::IO::DNSResolver.new
      expect(resolver.resolve("localhost")).to eq(Resolv::IPv4.create("127.0.0.1")).or eq(Resolv::IPv6.create("::1"))
    end

    it "resolves hostnames" do
      resolver = Celluloid::IO::DNSResolver.new
      expect(resolver.resolve("localhost")).to eq(Resolv::IPv4.create("127.0.0.1")).or eq(Resolv::IPv6.create("::1"))
    end

    it "resolves domain names" do
      resolver    = Celluloid::IO::DNSResolver.new
      nameservers = resolver.resolve("celluloid.io")
      expect(nameservers).to include Resolv::IPv4.create("104.28.21.100")
      expect(nameservers).to include Resolv::IPv4.create("104.28.20.100")
    end

    it "resolves CNAME responses" do
      resolver = Celluloid::IO::DNSResolver.new
      results = resolver.resolve("www.google.com")
      if results.is_a?(Array)
        results.all? { |i| expect(i).to be_an_instance_of(Resolv::IPv4) }
      else
        expect(results).to be_an_instance_of(Resolv::IPv4)
      end
      # www.yahoo.com will be resolved randomly whether multiple or
      # single entry.
      results = resolver.resolve("www.yahoo.com")
      if results.is_a?(Array)
        results.all? { |i| expect(i).to be_an_instance_of(Resolv::IPv4) }
      else
        expect(results).to be_an_instance_of(Resolv::IPv4)
      end
    end
  end
end
