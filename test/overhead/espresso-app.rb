$:.unshift ::File.expand_path('../../../lib', __FILE__)
require 'e'
class App < E
  map '/'
  def index
    "Hello World!"
  end
end
opts = {:server => :Thin}
(port = $*[0]) && (opts[:port] = port)
App.run opts
