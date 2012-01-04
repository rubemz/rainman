require 'spec_helper'

describe Rainman::Driver::Runner do
  before do
    @handler = mock("Handler")
    @handler.stub(:hello).and_return(:hello)
    @handler.class.stub(:handler_name).and_return(:name)
    @handler.class.stub(:validations).and_return({ :global => Rainman::Option.new(:global), :validate => :me })
  end

  let(:handler)     { @handler }
  let(:name)        { :name }
  let(:validations) { @handler.class.validations }
  subject           { Rainman::Driver::Runner.new(handler) }

  context "Accessors" do
    its(:name)        { should eql(name) }
    its(:handler)     { should eql(handler) }
    its(:validations) { should eql(validations) }
  end


  describe "#execute" do
    it "should validate globally" do
      validations[:global].should_receive(:validate!).with(1)
      subject.execute(@handler, :hello, 1)
    end

    it "should validate locally" do
      validations.merge!(name => Rainman::Option.new(name))
      validations[:global].should_receive(:validate!).with(1)
      validations[name].should_receive(:validate!)
      subject.execute(@handler, :hello, 1)
    end
  end

  describe "#method_missing" do
    it "should delegate to the handler" do
      args = { :arg => 1 }
      handler.should_receive(:hello).with(args).once
      subject.hello(args)
    end

    it { expect { subject.missing }.to raise_error(NoMethodError) }
  end
end
