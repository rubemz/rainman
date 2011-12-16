require 'spec_helper'

describe Rainman::Driver do
  describe "#register_handler" do
    module Mod1
      extend Rainman::Driver
      class Vern
        def my_method(opts = {})
          :vern
        end
      end

      class Uhoh
        def my_method(opts = {})
          :uhoh
        end
      end

      register_handler(:vern)
      register_handler(:uhoh) do |config|
        config[:hot] = true
      end

      define_action :my_method do
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
      expect {
        module Mod2
          extend Rainman::Driver
          register_handler(:what)
        end
      }.to raise_error("Unknown handler 'Mod2::What'")
    end

    it "should yield a config" do
      Mod1::Vern.config.should eql({})
      Mod1::Uhoh.config.should eql({ :hot => true})
    end

    it "should keep track of it's handlers" do
      Mod1::handlers.should include(:vern, :uhoh)
    end
  end

  describe "#define_action" do
    it "should define a method" do
      Mod1.should respond_to(:my_method)
    end
  end

  describe "#add_handler" do
    before(:each) do
      module Mod3
        extend Rainman::Driver
        class Blah; end
      end

      Mod3::instance_variable_set('@handlers', [])
    end

    it "should add a handler" do
      Mod3::handlers.should be_empty
      Mod3.send(:add_handler, :blah)
      Mod3::handlers.should include(:blah)
    end

    it "should raise an error on duplicate handlers" do
      Mod3::handlers.should be_empty
      Mod3.send(:add_handler, :blah)
      expect {
        Mod3.send(:add_handler, :blah)
      }.to raise_error("Handler already registered 'Mod3::Blah'")
    end
  end

  describe '#options' do
    subject { Mod1::options }
    it { should be_a(Hash) }
    it { should include(:global) }
  end

  describe '#add_option' do
    module AddOption
      extend Rainman::Driver
      define_action(:test) do |m|
        m.add_option :arg
        m.add_option :other => { :required => true }
      end
    end

    it "should add an :arg option" do
      hash = {
        :arg   => true,
        :other => { :required => true }
      }
      AddOption::options[:test].all.should include(hash)
    end
  end

  context "Calling a driver method" do
    module DriverMethods
      extend Rainman::Driver

      define_action(:test) do |m|
        m.add_option :what => { :required => true }
      end
    end

    it "should raise an error when :what is not specified" do
      expect { DriverMethods::test }.to raise_error(":what is required")
    end
  end

  describe "#actions" do
    subject { Mod1::actions }

    it { should include(:my_method) }
  end

  describe "#add_option_all" do
    module OptionAll
      extend Rainman::Driver

      add_option_all :all => { :required => true }

      define_action :test
      define_action :other
    end

    it "should add a param to all methods" do
      expect { OptionAll::test }.to raise_error(":all is required")
      expect { OptionAll::other }.to raise_error(":all is required")
    end
  end

  describe "#with_handler" do
    it "should raise an error with an invalid handler" do
      expect { Mod1::with_handler(:wtf) }.to raise_error(":wtf is not a valid handler")
    end

    it "should call the action with the specified handler" do
      Mod1::with_handler(:vern).should be_a(Mod1::Vern)
      Mod1::with_handler(:uhoh).should be_a(Mod1::Uhoh)

      Mod1::with_handler(:vern).my_method.should eql(:vern)
      Mod1::with_handler(:uhoh).my_method.should eql(:uhoh)
    end

    it "should yield a handler" do
      hit = false
      Mod1::with_handler(:vern) do |handler|
        handler.should be_a(Mod1::Vern)
        hit = true
      end

      hit.should be_true, "A handler was not yielded"
    end
  end

  describe "#default_handler" do
    module DefaultHandler
      extend Rainman::Driver

      class One
        def my_method(opts = {})
          [:one, opts]
        end
      end

      class Two
        def my_method(opts = {})
          [:two, opts]
        end
      end

      register_handler :one
      register_handler :two

      default_handler :one

      define_action :my_method
    end

    it "should use a default handler" do
      DefaultHandler::my_method.should eql([:one, {}])
      DefaultHandler::with_handler(:two).my_method.should eql([:two,{}])
      DefaultHandler::my_method.should eql([:one, {}])
    end

    it "should send the options" do
      DefaultHandler::my_method(:test => 1).should eql([:one, {:test => 1}])
    end

    it "should raise an error without a default handler" do
      expect { Mod1::my_method }.to raise_error("no handler specified")
    end
  end

  describe "#with_options" do
    module WithOptions
      extend Rainman::Driver
      class Vern
        def my_method(opts = {})
          :vern
        end
      end

      class Uhoh
        def my_method(opts = {})
          :uhoh
        end
      end

      register_handler(:vern)
      register_handler(:uhoh) do |config|
        config[:hot] = true
      end

      define_action :my_method do
      end
    end
    class IncludeDriver
      include WithOptions::with_options
    end

    subject { IncludeDriver.new }

    it { should respond_to(:my_method) }


    context "Prefixing" do
      class IncludeDriverPrefix
        include WithOptions::with_options(:prefix => :something)
      end

      subject { IncludeDriverPrefix.new }

      it { should     respond_to(:something) }
      it { should_not respond_to(:my_method) }

      it "should deletegate :something to the driver" do
        subject.something.with_handler(:vern).my_method
      end
    end

    context "Options" do
      class OptionsDriver
        include WithOptions::with_options(:default_handler => :vern)
      end

      pending "This behavior is undecided" do
        class OptionsDriverOther
          include WithOptions::with_options(:default_handler => :uhoh)
        end
      end

      subject { OptionsDriver.new }

      it "should use the default_handler" do
        subject.my_method.should eql(:vern)
      end
    end
  end

end
