require "socket"
require "json"
require_relative "user"

class Server
  def initialize()
    @channels = Array.new
    @clients = Hash.new
  end

  def build_server(host, port)
    @server = TCPServer.open(host, port)
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
        begin
          send(method.to_sym, client, *args[1..-1])
        rescue ArgumentError
          reply client, false, "Wrong number of Arguments."
        end
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
    if @clients.has_key?(client)
      reply client, false, "You've already logined."
      return
    end
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

  def logged_in?(client)
    t = @clients.has_key?(client)
    reply client, false, "Please Login First." unless t
    t
  end

  def message(client, *message)
    return unless logged_in?(client)
    sender = @clients[client]
    original_message = message.join(' ')
    reply_message = "#{sender.name}: #{original_message}"
    @clients.each do |other_client, other_user|
      if other_client != client
        reply other_client, true, reply_message
      end
    end
    reply client, true, "Message sent."
  end

  def create(client, channel)
    return unless logged_in?(client)
    if @channels.include?(channel)
      reply client, false, "This Channel is existed."
      return
    end
    @channels << channel
    reply client, true, "Channel Created."
  end

  def join(client, channel)
    return unless logged_in?(client)
    if @channels.include?(channel)
      @clients[client].current_channel = channel
      reply client, true, "Joined Channel Successfully."
    else
      reply client, false, "This Channel doesn't exist."
    end
  end

  def list(client)
    return unless logged_in?(client)
  end
end
