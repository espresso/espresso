module ECoreTest__ContentType

  class App < E

    content_type '.txt'

    setup :xml do
      content_type  '.xml'
    end

    setup :readme do
      content_type 'readme'
    end

    format '.json'

    def index
      content_type('Blah!') if format == '.json'
    end

    def xml
    end

    def json
      content_type '.json'
    end

    def read something

    end

    def readme

    end

  end

  Spec.new App do

    get
    is_content_type?('.txt')

    get :xml
    is_content_type?('.xml')

    get :read, 'feed.json'
    is_content_type?('.json')

    rsp = get :json
    is_content_type?('.json')

    Ensure 'type set by `content_type` is overridden by type set by format' do
      get :readme
      is_content_type?('readme')

      get 'readme.json'
      is_content_type?('.json')
    end

    Testing 'setup by giving action name along with format' do
      get
      is_content_type?('.txt')
      get 'index.json'
      is_content_type?('Blah!')
    end

  end
end
