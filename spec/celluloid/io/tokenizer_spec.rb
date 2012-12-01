require 'spec_helper'

describe Celluloid::IO::Tokenizer do
  let(:delimiter) { "X" }
  let(:example_strings) { %w(foo bar baz) }
  let(:joined_string) { example_strings.join(delimiter) << delimiter }
  let(:untokenizable_string) { example_strings.join }

  subject { Celluloid::IO::Tokenizer.new(delimiter) }

  it "extracts data at a specified boundary" do
    subject.extract(joined_string).should eq example_strings
  end

  it "flushes its contents" do
    subject.extract(untokenizable_string).should eq []
    subject.flush.should eq untokenizable_string
  end

  it "knows if it's empty" do
    subject.should be_empty
    subject.extract(untokenizable_string).should eq []
    subject.should_not be_empty
  end
end