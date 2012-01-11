require 'spec_helper'


describe "Rainman::Driver" do
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
  end

  describe "::extended" do
    it "extends base with base" do
      m = Module.new
      m.should_receive(:extend).with(m)
      Rainman::Driver.extended(m)
    end
  end

  describe "::all" do
    it "returns an array of registered drivers" do
      Rainman::Driver.all.should == [@module]
    end
  end

  describe "#handlers" do
    it "returns an empty hash" do
      @module.handlers.should == {}
    end

    it "raises exception when accessing an unknown key" do
      expect { @module.handlers[:foo] }.to raise_error(Rainman::InvalidHandler)
    end

    it "raises exception when accessing a nil key" do
      expect { @module.handlers[nil] }.to raise_error(Rainman::NoHandler)
    end
  end

  describe "#config" do
    it "returns an empty hash" do
      @module.config.should be_a Hash
      @module.config.should eq(@module.instance_variable_get(:@config))
    end
  end

  describe "#with_handler" do
    before do
      @klass = Class.new do
        def hi; :hi_handler!; end
        def self.handler_name; :blah; end
      end
      @handler = @klass.new
      runner = Rainman::Runner.new(@handler)
      @handler.stub(:runner).and_return(runner)
      @module.stub(:current_handler_instance).and_return(@handler)
    end

    it "should temporarily change the current handler" do
      old_handler = :old_lady
      @module.should_receive(:set_current_handler).with(:blah)
      @module.should_receive(:set_current_handler).with(old_handler)
      @module.stub(:current_handler).and_return(old_handler)
      @module.with_handler(:blah) {}
    end

    it "should raise an error without a block" do
      expect { @module.with_handler(:blah) }.to raise_error(Rainman::MissingBlock)
    end

    it "yields the runner" do
      res = @module.with_handler :blah do |runner|
        runner.should be_a(Rainman::Runner)
        runner.hi
      end
      res.should == :hi_handler!
    end
  end

  describe "#set_default_handler" do
    it "sets @default_handler" do
      @module.set_default_handler :blah
      @module.instance_variable_get(:@default_handler).should == :blah
    end
  end

  describe "#default_handler" do
    it "gets @default_handler" do
      expected = @module.instance_variable_get(:@default_handler)
      @module.default_handler.should eq(expected)
    end
  end

  describe "#included" do
    it "extends base with Forwardable" do
      klass = Class.new
      klass.should_receive(:extend).with(::Forwardable)
      klass.stub(:def_delegators)
      klass.send(:include, @module)
    end

    it "sets up delegation for singleton methods" do
      klass = Class.new
      klass.should_receive(:def_delegators).with(@module, *@module.singleton_methods)
      klass.send(:include, @module)
    end
  end

  describe "#handler_instances" do
    it "returns @handler_instances" do
      @module.send(:handler_instances).should == {}
      @module.instance_variable_set(:@handler_instances, { :foo => :test })
      @module.send(:handler_instances).should == { :foo => :test }
    end
  end

  describe "#set_current_handler" do
    it "sets @current_handler" do
      @module.send(:set_current_handler, :blah)
      @module.instance_variable_get(:@current_handler).should == :blah
      @module.send(:set_current_handler, :other)
      @module.instance_variable_get(:@current_handler).should == :other
    end
  end

  describe "#current_handler_instance" do
    before do
      @class = Class.new
      @klass = @class.new
      @module.handlers[:abc] = @class
      @module.send(:set_current_handler, :abc)
    end

    it "returns the handler instance" do
      @module.send(:handler_instances).merge!(:abc => @klass)
      @module.send(:current_handler_instance).should == @klass
    end

    it "sets the handler instance" do
      @module.handlers[:abc] = @class
      @class.should_receive(:new).and_return(@klass)
      @module.send(:current_handler_instance).should be_a(@class)
    end
  end

  describe "#current_handler" do
    it "returns @current_handler if set" do
      @module.instance_variable_set(:@current_handler, :blah)
      @module.send(:current_handler).should == :blah
    end

    it "returns @default_handler if @current_handler is not set" do
      @module.instance_variable_set(:@current_handler, nil)
      @module.instance_variable_set(:@default_handler, :blah)
      @module.send(:current_handler).should == :blah
    end
  end

  describe "#register_handler" do
    before do
      @bob = Class.new do
        def self.name; 'Bob'; end
      end
      @module.const_set(:Bob, @bob)
    end

    it "adds the handler to handlers" do
      @module.send(:register_handler, :bob)
      @module.handlers.should have_key(:bob)
      @module.handlers[:bob].should == @bob
    end

    it "extends handler with handler methods" do
      @bob.should_receive(:extend).with(Rainman::Handler)
      @bob.stub(:config).and_return({})
      @module.send(:register_handler, :bob)
    end

    it "evaluates a block if given" do
      @module.send(:register_handler, :bob) do
        config[:test] = :omghi2u
      end
      @bob.config[:test].should == :omghi2u
    end
  end

  describe "#define_action" do
    it "creates the method" do
      @module.should_not respond_to(:blah)
      @module.send(:define_action, :blah)
      @module.should respond_to(:blah)

      klass = Class.new.new
      runner = Rainman::Runner.new(klass)
      klass.stub(:runner).and_return(runner)
      @module.stub(:current_handler_instance).and_return(klass)
      runner.should_receive(:send).with(:blah)

      @module.blah
    end
  end

  describe "#create_method" do
    it "raises AlreadyImplemented if the method has been defined" do
      @module.instance_eval do
        def blah; end
      end

      expect do
        @module.send(:create_method, :blah)
      end.to raise_error(Rainman::AlreadyImplemented)
    end

    it "adds the method" do
      @module.should_not respond_to(:blah)
      @module.send(:create_method, :blah, lambda { :hi })
      @module.should respond_to(:blah)
      @module.blah.should == :hi
    end
  end

  describe "#inject_handler_methods" do
    before do
      @bob = Class.new do
        def self.name; 'Bob'; end
      end
      @module.const_set(:Bob, @bob)
    end

    it "extends Handler" do
      @bob.should_receive(:extend).with(Rainman::Handler)
      @module.send(:inject_handler_methods, @bob, :bob)
    end

    it "sets @handler_name class var" do
      @module.send(:inject_handler_methods, @bob, :bob)
      @bob.handler_name.should == :bob
    end

    it "sets @config class var" do
      @module.send(:inject_handler_methods, @bob, :bob)
      @bob.config.should eq(@bob.instance_variable_get(:@config))
    end

    it "instance_evals block" do
      blk = lambda { }
      @module.should_receive(:instance_eval_value)
      @module.send(:inject_handler_methods, @bob, :bob, &blk)
    end
  end

  describe "#namespace" do
    def create_ns_class(name, base)
      klass = Class.new do
        def hi; self.class.handler_name; end
        def self.handler_name; name; end
        def self.validations; { :global => Rainman::Option.new(:global) }; end
      end

      set_const(base, name.to_s.camelize.to_sym, klass)
    end

    def set_const(base, name, const)
      base.send(:remove_const, name) if base.const_defined?(name)
      base.const_set(name, const)
    end

    before do
      create_ns_class :abc, @module
      create_ns_class :xyz, @module
      create_ns_class :bob, @module::Abc
      create_ns_class :bob, @module::Xyz

      @module.namespaces.should be_empty
      @module.send(:register_handler, :abc)
      @module.send(:register_handler, :xyz)
      @module.set_default_handler :abc
      @module.send(:namespace, :bob)
      @module.namespaces.should include(:bob)
    end

    it "creates a method for the namespace" do
      @module.should respond_to(:bob)
    end

    it "returns a Runner" do
      @module.bob.should be_a(Rainman::Runner)
    end

    it "uses the right handler" do
      [:abc, :xyz].each do |h|
        expected = "MissDaisy::#{h.to_s.capitalize}::Bob"
        @module.with_handler(h) do |handler|
          handler.bob.hi.should == expected
        end
      end
    end
  end

  describe "#instance_eval_value" do
    before do
      @hash = {}
      @module.send(:instance_eval_value, :config, @hash) do
        config[:blah] = :one
      end
    end

    it "evals block setting config" do
      @hash.should have_key(:blah)
      @hash[:blah].should == :one
    end
  end
end
