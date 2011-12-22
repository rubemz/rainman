require 'spec_helper'

describe Rainman::Exceptions do
  describe "AlreadyImplemented" do
    it "raises with message" do
      expect do
        raise Rainman::Exceptions::AlreadyImplemented, :blah
      end.to raise_error(
        Rainman::Exceptions::AlreadyImplemented,
        /Method :blah already exists!/
      )
    end
  end

  describe "InvalidHandler" do
    it "raises with message" do
      expect do
        raise Rainman::Exceptions::InvalidHandler, :blah
      end.to raise_error(
        Rainman::Exceptions::InvalidHandler,
        /Handler :blah is invalid! Maybe you need to call 'register_handler :blah'\?/
      )
    end
  end
end
