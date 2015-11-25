require "socket"
require "json"
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
    valid_methods = %w[login message list create join exit]
    loop {
      message = client.gets.chomp
      args = parse(message)
      method = args[0].downcase
      if valid_methods.include?(method)
        send(method.to_sym, client, args[1..-1])
      else
        reply client, false, "This is not a valid method."
      end
    }
  end

  def reply(client, success, message)
    reply_hash = {:success => success, :message => message}
    reply_json = JSON.generate(reply_hash)
    client.puts reply_json
  end

  def parse(message)
    message.strip.split
  end

  def login(client, username)
    @clients.each do |exist_client, user|
      if user.name == username
        reply client, false, "This Username has been used."
        return
      end
    end
    new_user = User.new(username)
    @clients[client] = new_user
    reply client, true, "Login Successed."
  end
  end
end
