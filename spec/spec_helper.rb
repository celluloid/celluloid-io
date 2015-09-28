require "rubygems"
require "bundler/setup"

module Specs
  ALLOW_SLOW_MAILBOXES = true # TODO: Remove hax.
end

require "celluloid/rspec"
require "celluloid/io"

Dir[*Specs::INCLUDE_PATHS].map { |f| require f }
