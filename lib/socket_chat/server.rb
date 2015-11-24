require "socket"

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
end
