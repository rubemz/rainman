require 'spec_helper'

describe Rainman::Configuration do
  subject { Rainman::Configuration.new(:global) }

  it "delegates #global to self.class.data" do
    subject.data.should eq(subject.class.data)
  end

  it "stores keys in self.class.data[name]" do
    subject[:blah] = :one
    subject.class.data.should have_key(:global)
    subject.class.data[:global].should have_key(:blah)
    subject.class.data[:global][:blah].should == :one
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
