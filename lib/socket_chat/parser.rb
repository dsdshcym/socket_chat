require "optparse"

class OptParser
  attr_accessor :address, :port

  def initialize
    @address = "localhost"
    @port    = 8000
  end

  def parse
    OptionParser.new do |opts|
      opts.on("-s", "--server [SERVER]", "Server's IP address (Default: localhost)") do |s|
        @address = s
      end

      opts.on("-p", "--port [PORT]", "Server's port (Default: 8000)") do |p|
        @port = p.to_i
      end

      opts.on("-h", "--help", "Print this help") do
        puts opts
        exit
      end
    end.parse!
  end
end
