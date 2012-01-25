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
    its(:name)    { should == :hello }
    its(:handler) { should eql(handler) }
    its(:driver)  { should eql(driver) }
    its(:config)  { should eql(config) }
  end

  describe "#initialize" do
    it "stores an optional block as @handler_initializer" do
      blk = lambda { |h| :block! }
      run = Rainman::Runner.new(:hello2, handler, driver, &blk)
      run.instance_variable_get(:@handler_initializer).should eq(blk)
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

  describe "#handler_initializer" do
    it "returns @handler_initializer" do
      blk = lambda { |h| :block! }
      run = Rainman::Runner.new(:hello2, handler, driver, &blk)
      run.send(:handler_initializer).should eq(blk)
    end
  end

  describe "#handler_instance" do
    it "initializes a new handler with #handler_initializer" do
      blk = lambda { |h| :block! }
      run = Rainman::Runner.new(:hello2, handler, driver, &blk)
      run.send(:handler_initializer).should_receive(:call).with(handler)
      run.send(:handler_instance)
    end

    it "initializes a new handler with #new when #handler_initializer is true" do
      run = Rainman::Runner.new(:hello2, handler, driver)
      handler.should_receive(:new)
      run.send(:handler_instance)
    end

    it "returns the handler class when #handler_initializer is falsey" do
      run = Rainman::Runner.new(:hello2, handler, driver, :initialize => false)
      run.send(:handler_instance).should == handler
    end
  end
end
