require 'spec_helper'

describe Rainman::Handler do
  before do
    Rainman::Driver.instance_variable_set(:@all, [])
    @module = Module.new do
      def self.name
        'MissDaisy'
      end
    end
    @module.extend Rainman::Driver
    Object.send(:remove_const, :MissDaisy) if Object.const_defined?(:MissDaisy)
    Object.const_set(:MissDaisy, @module)

    @class = Class.new do
      extend Rainman::Handler
    end

    @module.config[:blah] = {}

    @class.instance_variable_set(:@config, @module.config[:blah])
    @class.instance_variable_set(:@handler_name, :blah)
  end

  describe "#config" do
    it "returns the config" do
      @class.config.should eq @module.config[:blah]
    end
  end

  describe "#handler_name" do
    it "returns @handler_name" do
      @class.handler_name.should == :blah
      @class.handler_name.should eq @class.instance_variable_get(:@handler_name)
    end
  end
end
