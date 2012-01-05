require 'spec_helper'

describe "Rainman Exceptions" do

  def self.test_exception(klass, opts = {})
    describe "#{klass.to_s}" do
      it "raises with message" do
        const = Rainman.const_get(klass)
        args  = opts[:args]
        mesg  = opts[:message]
        expect { raise const, *args }.to raise_error(const, mesg)
      end
    end
  end

  test_exception :AlreadyImplemented,
    :args    => :blah,
    :message => "Method :blah already exists!"

  test_exception :InvalidHandler,
    :args    => :blah,
    :message => "Handler :blah is invalid! Maybe you need to call " <<
                "'register_handler :blah'?"

  test_exception :NoHandler,
    :message => "No handler is set! Maybe you need to call " <<
                "'set_default_handler'?"

  test_exception :MissingParameter,
    :args    => :blah,
    :message => "Missing parameter :blah!"

  test_exception :MissingBlock,
    :args    => :blah,
    :message => "Can't call :blah without a block!"
end
