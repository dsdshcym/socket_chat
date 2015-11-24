require "socket"

class Client
  def initialize(host, port)
    @server = TCPServer.new(host, port)
  end

  def run
    listen
    send
  end

  private

  def listen
    response = Thread.new do
      loop {
        message = @server.gets.chomp
        display message
      }
    end
    response.join
  end

  def send
    request = Thread.new do
      loop {
        message = $stdin.gets.chomp
        @server.puts(message)
      }
    end
    request.join
  end
end
