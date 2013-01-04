module ECoreTest__Charset

  class CharsetApp < E

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

  Spec.new CharsetApp do
    testing do
      get
      is_charset? 'ISO-8859-1'

      get :utf_16
      is_charset? 'UTF-16'

      get :utf_32
      is_charset? 'UTF-32'

      get :iso_8859_2
      is_charset? 'ISO-8859-2'
      is_content_type? '.xml'
    end

    testing 'setup by giving action name along with format' do
      get 'index.json'
      is_charset? 'UTF-32'
    end
  end
end
