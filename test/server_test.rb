require "test/unit"
require "shoulda"
require "json"
require_relative "../lib/socket_chat/server.rb"
require_relative "../lib/socket_chat/user.rb"

class TestServer < Test::Unit::TestCase
  def setup
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

  context "user login" do
    setup do
      @logged_username = "Alice"
      logged_user = User.new(@logged_username)
      logged_client = Client.new(:logged_client)
      @logged_client = logged_client
      @server.instance_eval do
        @clients[logged_client] = logged_user
      end
      @new_client = Client.new(:new_client)
      @new_username = "Bob"
    end

    should "successful using another client" do
      @server.send(:login, @new_client, @new_username)
      response_json = @new_client.response
      result = JSON.parse(response_json)
      assert_true result["success"]
    end

    should "failed using the same client" do
      @server.send(:login, @logged_client, @new_username)
      response_json = @logged_client.response
      result = JSON.parse(response_json)
      assert_false result["success"]
    end

    should "failed using the existing name" do
      @server.send(:login, @new_client, @logged_username)
      response_json = @new_client.response
      result = JSON.parse(response_json)
      assert_false result["success"]
    end
  end

  context "user send message" do
    context "before login" do
      setup do
        @new_client = Client.new(:new_client)
        @new_username = "Bob"
      end

      should "failed" do
        @server.send(:message, @new_client, @new_username)
        response_json = @new_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]
      end
    end

    context "after login" do
      setup do
        @logged_username = "Alice"
        logged_user = User.new(@logged_username)
        logged_client = Client.new(:logged_client)
        @logged_client = logged_client
        @server.instance_eval do
          @clients[logged_client] = logged_user
        end
      end

      should "success" do
        @server.send(:message, @logged_client, "Test")
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_true result["success"]
      end
    end
  end

  context "user create channel" do
    context "before login" do
      setup do
        @new_client = Client.new(:new_client)
        @new_channel = "TC"
      end

      should "failed" do
        @server.send(:create, @new_client, @new_channel)
        response_json = @new_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]
      end
    end
  end
end

class Client
  attr_reader :response

  def initialize(name)
    @name = name
  end

  def puts(message)
    @response = message
  end
end
