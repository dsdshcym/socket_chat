class User
  attr_accessor :name, :current_channel

  def initialize(username, channel=nil)
    @name = username
    @current_channel = channel
  end
end
