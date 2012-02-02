require 'spec_helper'

# This file is pulled right from ActiveSupport 3.1, but we'll add a few specs
# anyway :)
describe "Rainman support" do
  describe "String#constantize" do
    "String".constantize.should == String
    "Rainman".constantize.should == Rainman
    "Rainman::Driver".constantize.should == Rainman::Driver
  end

  describe "String#camelize" do
    "foo_bar".camelize.should == "FooBar"
    "some_module/some_class".camelize.should == "SomeModule::SomeClass"
  end

  describe "String#underscore" do
    "FooBar".underscore.should == "foo_bar"
    "SomeModule::SomeClass".underscore.should == "some_module/some_class"
  end

  describe "Hash#reverse_merge" do
    a = { :first => :ABC, :a => :a }
    b = { :first => :XYZ, :b => :b }

    c = a.reverse_merge(b)
    c.should_not == a
    c[:a].should == :a
    c[:b].should == :b
    c[:first].should == :ABC

    b.reverse_merge!(a)
    b[:first].should == :XYZ
    b[:a].should == :a
    b[:b].should == :b
  end

end
