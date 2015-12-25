require "socket"
require "json"

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
        if message[0] != '/'
          message = 'message ' + message
        else
          message = message[1..-1]
        end
        @server.puts(message)
      }
    end
  end

  def display(message)
    m = JSON.parse(message)["message"]
    if JSON.parse(message)["success"]
      puts m if !m.empty?
    else
      puts "ERROR: #{m}"
    end
  end
end
