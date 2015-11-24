require "socket"

class Client
  def initialize(host, port)
    @server = TCPSocket.new(host, port)
  end

  def run
    @response = nil
    @request = nil
    send
    listen
    @response.join
    @request.join
  end

  private

  def listen
    @response = Thread.new do
      loop {
        message = @server.gets.chomp
        display message
      }
    end
  end

  def send
    @request = Thread.new do
      loop {
        message = $stdin.gets.chomp
        @server.puts(message)
      }
    end
  end
end
