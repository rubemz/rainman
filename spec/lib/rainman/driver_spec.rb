require 'spec_helper'

describe Rainman::Driver do
  describe "#register_handler" do

    module Mod1
      extend Rainman::Driver
      class Vern
      end

      class Uhoh
      end

      register_handler(:vern)
      register_handler(:uhoh) do |config|
        config[:hot] = true
      end
    end


    it "should make Mod1 a Driver" do
      Mod1.should     be_a(Rainman::Driver)
      Mod1.should_not be_a(Rainman::Handler)
    end

    it "should make Mod1::Vern a Handler" do
      Mod1::Vern.should     be_a(Rainman::Handler)
      Mod1::Vern.should_not be_a(Rainman::Driver)
    end

    it "should raise an error for an unknow Handler" do
      expect do
        module Mod2
          extend Rainman::Driver
          register_handler(:what)
        end
      end.to raise_error("Unknown handler 'Mod2::What'")
    end

    it "should yield a config" do
      Mod1::Vern.config.should eql({})
      Mod1::Uhoh.config.should eql({ :hot => true})
    end
  end
end
