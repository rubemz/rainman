require 'spec_helper'

describe Rainman::Runner do
  before do
    @handler = mock("Handler")
    @handler.stub(:hello).and_return(:hello)
    @handler.class.stub(:handler_name).and_return(:name)
  end

  let(:handler)     { @handler }
  let(:name)        { :name }
  subject           { Rainman::Runner.new(handler) }

  context "Accessors" do
    its(:name)        { should eql(name) }
    its(:handler)     { should eql(handler) }
  end


  describe "#execute" do
    it "validates paramters"
  end

  describe "#method_missing" do
    it "should delegate to the handler" do
      args = { :arg => 1 }
      handler.should_receive(:hello).with(args).once
      subject.hello(args)
    end

    it "should raise an error on missing methods" do
      module Oops
        extend Rainman::Driver
        class Example
        end

        register_handler :example
        define_action :missing
        set_default_handler :example
      end

      expect { Oops.missing }.to raise_error(Rainman::MissingHandlerMethod)
    end

    it { expect { subject.missing }.to raise_error(NoMethodError) }
  end
end
#raise Rainman::MissingHandlerMethod.new(:method => method, :class => name)
