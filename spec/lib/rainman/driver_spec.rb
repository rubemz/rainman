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
        expect {
          subject.register_handler('asdf')
        }.to raise_error(/uninitialized constant RegisterHandle::Asdf/)
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

      subject { DefineAction }

      its(:actions) { should include(:action, :second_action) }

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

  end
end
