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
    it "returns a hash" do
      @module.handlers.should be_a Hash
    end

    it "raises exception when accessing an unknown key" do
      expect { @module.handlers[:foo] }.to raise_error(Rainman::InvalidHandler)
    end

    it "raises exception when accessing a nil key" do
      expect { @module.handlers[nil] }.to raise_error(Rainman::NoHandler)
    end
  end

  describe "#with_handler" do
    before do
      @hello1 = Class.new
      @hello2 = Class.new

      @module.stub(:handlers).and_return(
        :hello1 => @hello1,
        :hello2 => @hello2
      )
      @module.stub(:current_handler).and_return(:hello2)
    end

    it "yields the given handler" do
      @module.with_handler :hello1  do |h|
        h.should eq @hello1
      end
    end

    it "yields the default handler without a name" do |h|
      @module.with_handler do |h|
        h.should eq @hello2
      end
    end

    it "returns the block value" do
      @module.with_handler { |h| :res }.should == :res
    end

    it "returns the handler if no block is given" do
      @module.with_handler.should eq @hello2
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

  describe "#set_current_handler" do
    it "sets @current_handler" do
      @module.set_current_handler :blah
      @module.instance_variable_get(:@current_handler).should == :blah
      @module.set_current_handler :other
      @module.instance_variable_get(:@current_handler).should == :other
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
      Rainman::Runner.should_receive(:new).with(:bob, MissDaisy::Bob, @module, {})
    end

    it "creates a new Runner" do
      @module.send(:register_handler, :bob)
    end

    describe ":class_name option" do
      it "allows a string" do
        @module.send(:register_handler, :bob, :class_name => 'MissDaisy::Bob')
      end

      it "allows a constant" do
        @module.send(:register_handler, :bob, :class_name => MissDaisy::Bob)
      end
    end
  end

  describe "#define_action" do
    before do
      @klass = Class.new do
        def blah; :blah; end
        def desc; :bob_is_cool!; end
      end
      @module.stub(:with_handler).and_return(@klass.new)
    end

    it "creates the method" do
      @module.should_not respond_to(:blah)
      @module.send(:define_action, :blah)
      @module.should respond_to(:blah)

      @module.blah.should == :blah
    end

    it "aliases the method if :alias is supplied" do
      @module.should_not respond_to(:blah)
      @module.send(:define_action, :blah, :alias => :superBLAH)
      @module.should respond_to(:blah)
      @module.should respond_to(:superBLAH)

      @module.blah.should == :blah
      @module.superBLAH.should == :blah
    end

    it "delegates the method if :delegate_to is supplied" do
      @module.send(:define_action, :description, :delegate_to => :desc)
      @module.should respond_to(:description)
      @module.should_not respond_to(:desc)

      @module.description.should == :bob_is_cool!
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

  describe "#namespace", pending: true do
    def create_ns_class(name, base)
      klass = Class.new do
        def hi; self.class.handler_name; end
        def bye; :nonono!; end
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

      @module.send(:register_handler, :abc)
      @module.send(:register_handler, :xyz)
      @module.set_default_handler :abc
      @module.send(:namespace, :bob) do
        define_action :hi
      end
    end

    it "sets an instance variable" do
      [:abc, :xyz].each do |name|
        @module.with_handler(name) { |h| h.bob.hi }
        ivar = @module.instance_variable_get(:@bob)
        ivar.should be_a(Hash)
        ivar.should have_key(name)
        ivar[name].should be_a(Module)
      end
    end

    it "raises exception calling a method that isn't registered" do
      expect { @module.bob.bye }.to raise_error(NoMethodError)
    end

    it "raises no exception calling a method that is registered" do
      @module.bob.hi.should == "MissDaisy::Abc::Bob"
    end

    it "creates a method for the namespace" do
      @module.should respond_to(:bob)
    end

    it "returns an anonymous Module" do
      @module.bob.should be_a(Module)
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
end
