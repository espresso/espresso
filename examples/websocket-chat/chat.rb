require 'reel'

$:.unshift ::File.expand_path('../../../lib', __FILE__)
require 'e'

class Chat < E
  map :/
  Users = []

  def index
    render
  end

  def chat user
    render
  end

  def login user
    if stream = websocket?
      welcome = render_p(:welcome)
      Users.each {|u| u << welcome }
      Users << stream
      stream.on_message { |msg| post_message msg }
      stream.on_error { Users.delete stream }
      stream.read_every 1
    end
  end

  private

  def post_message message
    msg = render_p(:message, message: message)
    Users.each { |u| u << msg }
    msg
  end

end

Chat.run server: :Reel
