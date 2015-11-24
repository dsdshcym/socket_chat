require "socket"
require_relative "user"

class Server
  def initialize(host, port)
    @server = TCPServer.open(host, port)
    @users = Hash.new
    @channels = Hash.new
    @clients = Hash.new
  end

  def run
    loop {
      Thread.start(@server.accept) do |client|
        listen client
      end
    }.join
  end

  private

  def listen(client)
    loop {
      message = client.gets.chomp
      args = parse(message)
      send(args[0].downcase.to_sym, client, args[1..-1])
    }
  end

  def reply(client, message)
    client.puts message
  end

  def parse(message)
    message.strip.split
  end

  def login(client, username)
    @clients.each do |exist_client, user|
      if user.name == username
        reply client, "This Username has been used."
        return
      end
    end
    new_user = User.new(username)
    @clients[client] = new_user
  end
end
