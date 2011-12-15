require 'spec_helper'

describe Rainman::Option do
  before { @option = Rainman::Option.new('test') }
  describe "#initialize" do
    it "should set @name to test" do
      @option.name.should eql('test')
    end
  end

  describe "#add_option" do
    it "should add options to @all" do
      @option.add_option :arg
      @option.all.should include(:arg => true)
    end
  end

  describe "#required" do
    it "should return required args" do
      @option.add_option :arg => { :required => true }
      @option.required.should include(:arg)
    end
  end

  describe "#validate!" do
    it "should raise an error if opts are not a hash" do
      expect { @option.validate!([]) }.to raise_error("opts must be a hash")
    end

    it "should raise an error when a requried option is missing" do
      @option.add_option :arg => { :required => true }
      expect { @option.validate!({}) }.to raise_error(":arg is required")
    end
  end
end
