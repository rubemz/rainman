require 'spec_helper'

describe Rainman::Driver do
  describe "DSL" do
    module Extended
      extend Rainman::Driver::DSL
    end

    module ExtendedWithExistingAttrs
      extend Rainman::Driver::DSL

      self.actions  = [:action]
      self.handlers = [:handler]
    end

    module RegisterHandle
      extend Rainman::Driver::DSL

      class Mine; end
      class Other; end

      register_handler :mine
      register_handler :other do |config|
        config[:hot] = true
      end
    end

    describe "#self.extended" do
      subject { Extended }

      it { should respond_to(:actions, :handlers, :default_handler, :current_handler) }
      its(:actions)  { should be_empty }
      its(:handlers) { should be_empty }

      context "Predefined actions and handlers" do
        subject { ExtendedWithExistingAttrs }
        its(:actions)  { should_not be_empty }
        its(:handlers) { should_not be_empty }
      end
    end

    describe "#included" do
      class Included
        include Extended
      end

      subject { Included }

      it "should set @actions and @handlers" do
        subject.instance_variable_get('@actions').should be_empty
        subject.instance_variable_get('@handlers').should be_empty
      end
    end

    describe "#register_handler" do

      subject { RegisterHandle }

      its(:handlers) { should include(:mine, :other) }

      it "should store the class in the handler" do
        RegisterHandle::handlers[:mine].should  eql(RegisterHandle::Mine)
        RegisterHandle::handlers[:other].should eql(RegisterHandle::Other)
      end

      it "raise a uninitialized constant error" do
        # the .* is used because RBX displays the exception in a different format
        expect {
          subject.register_handler('asdf')
        }.to raise_error(/uninitialized constant.* RegisterHandle::Asdf/)
      end

      it "should yield a config" do
        RegisterHandle::Mine.config.should be_empty
        RegisterHandle::Other.config.should include(:hot => true)
      end
    end

    describe "#handlers" do
      subject { RegisterHandle }

      it { subject.handler_exists?(:other).should be_true }
      it { subject.handler_exists?(:mine).should be_true }
      it { subject.handler_exists?(:none).should be_false }
    end

    describe "#set_default_handler" do
      module DefaultHandler
        extend Rainman::Driver::DSL
        class One;end
        class Two;end

        register_handler :one
        register_handler :two
      end

      class DefaultHandlerClass
        include DefaultHandler
      end

      subject { DefaultHandlerClass }

      it "should set the default_handler" do
        subject.default_handler.should be_nil
        subject.set_default_handler :one
        subject.default_handler.should eql(DefaultHandler::One)
        subject.current_handler.should be_a(DefaultHandler::One)
      end

      it "should not set current_handler when it's already set" do
        subject.set_current_handler :one
        subject.set_default_handler :two
        subject.current_handler.should be_a(DefaultHandler::One)
        subject.default_handler.should eql(DefaultHandler::Two)
      end
    end

    describe "#set_current_handler" do
      module CurrentHandler
        extend Rainman::Driver::DSL
        class One;end
        class Two;end

        register_handler :one
        register_handler :two
      end

      subject { CurrentHandler }

      it "should set the current_handler without a default_driver" do
        subject.default_handler.should be_nil
        subject.current_handler.should be_nil

        subject.set_current_handler :one
        subject.current_handler.should be_a(CurrentHandler::One)
        subject.default_handler.should be_nil
      end

      it "should set the current_handler with a default_handler" do
        subject.set_default_handler :one
        subject.default_handler.should eql(CurrentHandler::One)

        subject.set_current_handler :two
        subject.current_handler.should be_a(CurrentHandler::Two)

        subject.default_handler.should eql(CurrentHandler::One)
      end
    end

    describe "#define_action" do
      module DefineAction
        extend Rainman::Driver::DSL
        class One
          def action
            :action_one
          end

          def second_action
            :second_action_one
          end
        end

        class Two
          def action
            :action_two
          end

          def second_action
            :second_action_two
          end
        end

        register_handler :one
        register_handler :two

        define_action :action
        define_action :second_action
      end

      class NoDefaultHandler
        include DefineAction
      end

      subject { DefineAction }

      its(:actions) { should include(:action, :second_action) }

      it "should raise an error without a default or current handler" do
        expect { NoDefaultHandler.new.action }.to raise_error(/A default_handler/)
      end

      context "Class including a driver" do
        class DefineActionClass
          include DefineAction
          set_default_handler :one
        end

        subject { DefineActionClass.new }
        it { should respond_to(:action) }
        it { should respond_to(:second_action) }

        it "should delegate to the handler" do
          subject.action.should        eql(:action_one)
          subject.second_action.should eql(:second_action_one)
        end

      end
    end

    context "Isolation" do
      module Isolation
        extend Rainman::Driver::DSL
        class Lonely
          class Alone
            def time
              :forever
            end
          end

          def solitude
            true
          end
        end

        class Friends
          class Alone
            def time
              :never
            end
          end

          def solitude
           false
          end
        end

        register_handler :lonely
        register_handler :friends

        define_action :solitude

        define_namespace :alone do
          define_action :time
        end
      end

      class IsolationClass
        include Isolation
        set_default_handler :lonely
      end

      class IsolationClass2
        include Isolation
        set_default_handler :friends
      end

      it "should isolate it's self" do
        IsolationClass::default_handler.should  eql(Isolation::Lonely)
        IsolationClass2::default_handler.should eql(Isolation::Friends)

        IsolationClass.new.solitude.should  be_true
        IsolationClass2.new.solitude.should be_false

        IsolationClass.new.alone.time.should == :forever
        IsolationClass2.new.alone.time.should == :never
      end
    end

    describe "#current_handler" do
      module CurrentHandler
        extend Rainman::Driver::DSL
        class One
          def hello
            :one
          end
        end

        class Two
          def hello
            :two
          end
        end

        define_action :hello

        register_handler :one
        register_handler :two
      end

      class CurrentHandlerClass
        include CurrentHandler
        set_default_handler :one
      end
      before { @current_handler = CurrentHandlerClass.new }

      it "should use the current_handler" do
        @current_handler.with_handler(:one).hello.should eql(:one)
        @current_handler.with_handler(:two).hello.should eql(:two)
        @current_handler.hello.should eql(:one)
      end

      it "should yield a block with :one" do
        yield_test = mock()
        yield_test.should_receive(:tap)
        @current_handler.with_handler(:one) do |handler|
          handler.hello.should eql(:one)
          yield_test.tap
        end
      end

      it "should yield a block with :two" do
        yield_test = mock()
        yield_test.should_receive(:tap)
        @current_handler.with_handler(:two) do |handler|
          handler.hello.should eql(:two)
          yield_test.tap
        end
      end
    end

    describe "Namespacing" do
      module Domain
        extend Rainman::Driver::DSL
        class Opensrs
          class Nameservers
            def transfer
            end
          end
        end

        register_handler :opensrs
        define_namespace :nameservers do
          define_action :transfer
        end
      end

      class DomainClass
        include Domain
        set_default_handler :opensrs
      end

      it "should return the namespace handler" do
        DomainClass.new.nameservers.should be_a(Domain::Opensrs::Nameservers)
      end

      it "should memoize the namespace handler" do
        domain = DomainClass.new
        ns = domain.nameservers
        domain.nameservers.should be(ns)
      end

      it "should include DSL" do
        domain = DomainClass.new
        ns = domain.nameservers.class
        Rainman::Driver::DSL.instance_methods.each do |meth|
          ns.should respond_to(meth)
        end
      end
    end

    describe '@options' do
      module AddOption
        extend Rainman::Driver
        define_action(:test) do |m|
          m.add_option :arg
          m.add_option :other => { :required => true }
        end
      end

      it { Extended::options.should be_a(Hash) }
      it { Extended::options.should include(:global) }

      it "should add an :arg option" do
        hash = {
          :arg   => true,
          :other => { :required => true }
        }
        AddOption::options[:test].all.should include(hash)
      end

      context "Calling a driver method" do
        module DriverMethods
          extend Rainman::Driver

          class One
            def hello
            end
          end

          register_handler :one

          define_action(:hello) do |m|
            m.add_option :what => { :required => true }
          end
        end

        class DriverMethodsClass
          include DriverMethods
          set_default_handler :one
        end

        it "should raise an error when :what is not specified" do
          d = DriverMethodsClass.new
          expect { d.hello }.to raise_error(":what is required")
        end
      end
    end

    describe "#add_option_all" do
      module OptionAll
        extend Rainman::Driver
        class One
          def hello
          end
        end

        register_handler :one

        add_option_all :all => { :required => true }

        define_action :hello
        define_action :other
      end

      class OptionAllClass
        include OptionAll
        set_default_handler :one
      end

      it "should add a param to all methods" do
        expect { OptionAllClass.new.hello }.to raise_error(":all is required")
        expect { OptionAllClass.new.other }.to raise_error(":all is required")
      end
    end

  end # DSL
end # Driver
