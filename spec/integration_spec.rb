require 'spec_helper'
require File.expand_path('../../example/domain.rb', __FILE__)

describe "Rainman integration" do
  describe Domain do
    its(:handlers) do
      should == {
        :enom    => Domain::Enom,
        :opensrs => Domain::Opensrs
      }
    end

    its(:config) do
      should == {
        :user    => :global,
        :enom    => { :user => :enom_user },
        :opensrs => {}
      }
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
