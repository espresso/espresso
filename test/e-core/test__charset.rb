module ECoreTest__Charset

  class App < E

    charset 'ISO-8859-1'

    setup :utf_16 do
      content_type '.txt', :charset => 'UTF-16'
    end

    setup :utf_32 do
      content_type '.txt'
    end

    format '.json'
    
    def index
      charset 'UTF-32' if json?
      __method__
    end

    def utf_16
      __method__
    end

    def utf_32
      content_type '.txt', :charset => 'UTF-32' # making sure it keeps charset
      __method__
    end

    def iso_8859_2
      content_type '.xml', :charset => 'ISO-8859-2'
    end

  end

  Spec.new App do

    def is_of_charset response, charset
      prove(response.header['Content-Type']) =~ %r[charset=#{Regexp.escape charset}]
    end

    get
    check(last_response).is_of_charset 'ISO-8859-1'

    get :utf_16
    check(last_response).is_of_charset 'UTF-16'

    get :utf_32
    check(last_response).is_of_charset 'UTF-32'

    get :iso_8859_2
    check(last_response).is_of_charset 'ISO-8859-2'
    prove(last_response.header['Content-Type']) =~ %r[#{Rack::Mime::MIME_TYPES.fetch '.xml'}]

    Testing 'setup by giving action name along with format' do
      get 'index.json'
      check(last_response).is_of_charset 'UTF-32'
    end
  end
end
