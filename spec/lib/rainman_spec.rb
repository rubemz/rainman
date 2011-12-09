require 'spec_helper'

describe Rainman do
  before(:each) do
    Rainman.instance_variable_set('@load_strategy', nil)
  end

  describe "#load_strategy" do
    its(:load_strategy) { should eql(:autoload) }

    it "should set the load_strategy" do
      Rainman.load_strategy :require
      Rainman.load_strategy.should eql(:require)

      Rainman.load_strategy :autoload
      Rainman.load_strategy.should eql(:autoload)
    end

    it "should raise an error on invalid strategy" do
      expect {
        Rainman.load_strategy :invalid
      }.to raise_error(':invalid is not a recognized strategy')
    end
  end
end
