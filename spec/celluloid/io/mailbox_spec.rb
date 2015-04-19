CelluloidSpecs.require('shared/shared_examples_for_mailbox')

RSpec.describe Celluloid::IO::Mailbox do
  it_behaves_like "a Celluloid Mailbox"
end
