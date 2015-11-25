require "test/unit"
require "shoulda"
require_relative "../lib/socket_chat/server.rb"

class TestServer < Test::Unit::TestCase
  context "Server" do
    setup do
      @server = Server.new()
    end

    context "parsing message" do
      setup do
        @correct_args           = ["LOGIN", "test"]
        @message_without_spaces = "LOGIN test"
        @message_with_spaces    = "    LOGIN test   "
      end

      should "correctly parse a message without leading and trailing spaces" do
        args = @server.send(:parse, @message_without_spaces)
        assert_equal @correct_args, args
      end

      should "correctly parse a message with leading and trailing spaces" do
        args = @server.send(:parse, @message_with_spaces)
        assert_equal @correct_args, args
      end
    end

    end
  end
end
