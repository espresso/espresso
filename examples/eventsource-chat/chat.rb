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
    event_stream do |stream|
      Users.each {|u| u.event('welcome'); u.data(user)}
      Users << stream
      stream.on_error { Users.delete stream }
    end
  end

  def post_message user
    msg = render_p(:message)
    Users.each { |u| u.data msg }
    msg
  end

end

Chat.run server: :Reel
