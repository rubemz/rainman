require 'spec_helper'

describe "Rainman Exceptions" do
  describe "AlreadyImplemented" do
    it "raises with message" do
      expect do
        raise Rainman::AlreadyImplemented, :blah
      end.to raise_error(
        Rainman::AlreadyImplemented,
        /Method :blah already exists!/
      )
    end
  end

  describe "InvalidHandler" do
    it "raises with message" do
      expect do
        raise Rainman::InvalidHandler, :blah
      end.to raise_error(
        Rainman::InvalidHandler,
        /Handler :blah is invalid! Maybe you need to call 'register_handler :blah'\?/
      )
    end
  end

  describe "MissingParameter" do
    it "raises with message" do
      expect do
        raise Rainman::MissingParameter, :blah
      end.to raise_error(
        Rainman::MissingParameter,
        /Missing parameter :blah!/
      )
    end
  end
end
