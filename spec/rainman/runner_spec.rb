require 'spec_helper'

describe Rainman::Runner do
  before do
    @driver  = mock("Driver")
    @driver.stub(:handlers).and_return({})

    @handler = mock("Handler")
    @handler.stub(:hi).and_return(:salutations)
    @handler.stub(:new).and_return(@handler)
  end

  let(:config)   { { :this => :old_config } }
  let(:handler)  { @handler }
  let(:driver)   { @driver }
  subject        { Rainman::Runner.new(:hello, handler, driver, config) }

  context "Accessors" do
    its(:handler) { should eql(handler) }
    its(:config)  { should eql(config) }
  end

  describe "#initialize" do
    it "adds new object to @driver.handlers" do
      expect do
        Rainman::Runner.new(:hello2, handler, driver)
      end.to change { driver.handlers.count }.by(1)

      driver.handlers.should have_key(:hello2)
    end
  end

  describe "#method_missing" do
    it "should delegate to the handler" do
      args = { :arg => 1 }
      handler.should_receive(:hi).with(args).once
      subject.hi(args)
    end

    it { expect { subject.missing }.to raise_error(NoMethodError) }
  end
end
