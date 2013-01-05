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
      # making sure charset are kept
      content_type '.txt', :charset => 'UTF-32' 
      __method__
    end

    def iso_8859_2
      content_type '.xml', :charset => 'ISO-8859-2'
    end

  end

  Spec.new CharsetApp do
    Testing do
      get
      is('ISO-8859-1').current_charset?

      get :utf_16
      is('UTF-16').current_charset?

      get :utf_32
      is('UTF-32').current_charset?

      get :iso_8859_2
      is('ISO-8859-2').current_charset?
      is('.xml').current_content_type?
    end

    Testing 'setup by giving action name along with format' do
      get 'index.json'
      is('UTF-32').current_charset?
    end
  end
end
