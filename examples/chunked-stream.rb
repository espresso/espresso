require 'reel'

$:.unshift ::File.expand_path('../../lib', __FILE__)
require 'e'

class App < E
  map :/

  def index a = 'a', z = 'z'
    chunked_stream do |body|
      body << "<html>#{' '*1024}" # sending a payload
      (a..z).each do |c|
        body << "<div>#{c}</div>"
        sleep 0.5
      end
      body << "</html>"
      body.close
    end
  end

end

App.run server: :Reel
