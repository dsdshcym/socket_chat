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
        logged_user.current_channel = "Channel 0"
        logged_client = Client.new(:logged_client)
        @logged_client = logged_client
        @server.instance_eval do
          @clients[logged_client] = logged_user
        end

        100.times do |i|
          other_user = User.new("User#{i}")
          if i >=50
            other_user.current_channel = "Channel 0"
          else
            other_user.current_channel = "Channel 1"
          end
          other_client = Client.new("Client#{i}")
          @server.instance_eval do
            @clients[other_client] = other_user
          end
        end
      end

      should "success" do
        @server.send(:message, @logged_client, "Test")
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_true result["success"]
      end

      should "only send to client in the same channel" do
        @server.send(:message, @logged_client, "Test")
        clients = Hash.new
        @server.instance_eval { clients = @clients }
        clients.each do |client, user|
          if user.current_channel != "Channel 0"
            assert_nil client.response
          else
            response_json = client.response
            result = JSON.parse(response_json)
            assert_true result["success"]
            assert_equal "#{@logged_username}: Test", result["message"]
          end
        end
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

    context "after login" do
      setup do
        @logged_username = "Alice"
        @logged_client = Client.new(:logged_client)
        @new_channel = "NC"
        @old_channel = "OC"

        logged_user = User.new(@logged_username)
        logged_client = @logged_client
        old_channel = @old_channel
        @server.instance_eval do
          @clients[logged_client] = logged_user
          @channels = [old_channel]
        end
      end

      should "success to create a new channel" do
        @server.send(:create, @logged_client, @new_channel)
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_true result["success"]
        channels = nil
        @server.instance_eval { channels = @channels }
        assert_true channels.include?(@new_channel)
      end

      should "failed to create an existing channel" do
        @server.send(:create, @logged_client, @old_channel)
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]
        channels = nil
        @server.instance_eval { channels = @channels }
        assert_equal [@old_channel], channels
      end
    end
  end

  context "user join channel" do
    context "before login" do
      setup do
        @new_client = Client.new(:new_client)
        @new_channel = "TC"
      end

      should "failed" do
        @server.send(:join, @new_client, @new_channel)
        response_json = @new_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]
      end
    end

    context "after login" do
      setup do
        @logged_username = "Alice"
        @logged_client = Client.new(:logged_client)
        @logged_user = User.new(@logged_username)
        @new_channel = "NC"
        @old_channel = "OC"

        logged_user = @logged_user
        logged_client = @logged_client
        old_channel = @old_channel
        @server.instance_eval do
          @clients[logged_client] = logged_user
          @channels = [old_channel]
        end
      end

      should "success to join an existing channel" do
        @server.send(:join, @logged_client, @old_channel)
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_true result["success"]

        user_channel = nil
        logged_client = @logged_client
        @server.instance_eval do
          user_channel = @clients[logged_client].current_channel
        end
        assert_equal @old_channel, user_channel
      end

      should "failed to join a non-exist channel" do
        @server.send(:join, @logged_client, @new_channel)
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]

        user_channel = nil
        logged_client = @logged_client
        @server.instance_eval do
          user_channel = @clients[logged_client].current_channel
        end
        assert_equal nil, user_channel
      end
    end
  end

  context "user list channels" do
    context "before login" do
      setup do
        @new_client = Client.new(:new_client)
      end

      should "failed" do
        @server.send(:list, @new_client)
        response_json = @new_client.response
        result = JSON.parse(response_json)
        assert_false result["success"]
      end
    end

    context "after login" do
      setup do
        @logged_username = "Alice"
        @logged_client = Client.new(:logged_client)
        @logged_user = User.new(@logged_username)
        @old_channels = ["OC"]

        logged_user = @logged_user
        logged_client = @logged_client
        old_channels = @old_channels
        @server.instance_eval do
          @clients[logged_client] = logged_user
          @channels = old_channels
        end
      end

      should "success" do
        @server.send(:list, @logged_client)
        response_json = @logged_client.response
        result = JSON.parse(response_json)
        assert_true result["success"]
        assert_true response_json.include?("OC")
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
