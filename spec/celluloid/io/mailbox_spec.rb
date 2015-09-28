require "spec_helper"

RSpec.describe Celluloid::IO::Mailbox, library: :IO do
  it_behaves_like "a Celluloid Mailbox"
end
