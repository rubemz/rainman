require 'spec_helper'

describe Rainman::Configuration do
  subject { Rainman::Configuration.new(:global) }

  it "delegates #global to self.class.global" do
    subject.global.should eq(subject.class.global)
  end

  it "stores keys in self.class.global[name]" do
    subject[:blah] = :one
    subject.class.global.should have_key(:global)
    subject.class.global[:global].should have_key(:blah)
    subject.class.global[:global][:blah].should == :one
  end

  it "retrieves a global key when a local key does not exist" do
    subject[:user] = :global_user
    b = Rainman::Configuration.new(:b)
    b[:user].should == :global_user
  end

  it "retrieves a local key when it exists" do
    c = Rainman::Configuration.new(:c)
    c[:testc] = :this_is_the_test
    c[:testc].should == :this_is_the_test
  end

end
