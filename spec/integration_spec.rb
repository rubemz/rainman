require 'spec_helper'
require File.expand_path('../../example/domain.rb', __FILE__)

describe "Rainman integration" do
  describe Domain do
    describe "handlers" do
      subject { Domain.handlers }

      its([:enom])    { should == Domain::Enom }
      its([:opensrs]) { should == Domain::Opensrs }
    end

    describe "config" do
      subject { Domain.config }

      its([:user])    { should == :global }
      its([:enom])    { should be_a Hash }
      its([:opensrs]) { should be_a Hash }
    end

    its(:default_handler) { should == :opensrs }

    it "has instance methods for each namespace/action" do
      methods = subject.instance_methods.map(&:to_sym)
      methods.should include(:nameservers, :list, :transfer)
    end

    describe "Opensrs integration" do
      its(:list)              { should == :opensrs_list }
      its(:transfer)          { should == :opensrs_transfer }
      its("nameservers.list") { should == :opensrs_ns_list }
    end

    describe "Enom integration" do
      before :all do
        subject.set_default_handler :enom
      end

      after :all do
        subject.set_default_handler :opensrs
      end

      its(:list)              { should == :enom_list }
      its(:transfer)          { should == :enom_transfer }
      its("nameservers.list") { should == :enom_ns_list }
    end
  end
end
