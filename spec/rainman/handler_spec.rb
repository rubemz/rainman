require 'spec_helper'

describe Rainman::Handler do
  describe "#config" do
    subject { Rainman::Handler.config }
    it { should be_a(Hash) }
  end
end
