require "spec_helper"

RSpec.describe Celluloid::IO::UDPSocket, library: :IO do
  let(:payload) { "ohai" }
  let(:example_port) { assign_port }
  subject do
    Celluloid::IO::UDPSocket.new.tap do |sock|
      sock.bind example_addr, example_port
    end
  end

  after { subject.close }

  context "inside Celluloid::IO" do
    it "should be evented" do
      expect(within_io_actor { Celluloid::IO.evented? }).to be_truthy
    end

    it "sends and receives packets" do
      within_io_actor do
        subject.send payload, 0, example_addr, example_port
        expect(subject.recvfrom(payload.size).first).to eq(payload)
      end
    end
  end

  context "outside Celluloid::IO" do
    it "should be blocking" do
      expect(Celluloid::IO).not_to be_evented
    end

    it "sends and receives packets" do
      subject.send payload, 0, example_addr, example_port
      expect(subject.recvfrom(payload.size).first).to eq(payload)
    end
  end
end
