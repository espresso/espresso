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

    rsp = get
    expect(rsp.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.txt')

    rsp = get :xml
    expect(rsp.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.xml')

    rsp = get :read, 'feed.json'
    expect(rsp.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.json')

    rsp = get :json
    expect(rsp.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.json')

    Ensure 'type set by `content_type` is overridden by type set by format' do
      get :readme
      expect(last_response.header['Content-Type']) == 'readme'

      get 'readme.json'
      expect(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.json')
    end

    Testing 'setup by giving action name along with format' do
      get
      expect(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.txt')
      get 'index.json'
      expect(last_response.header['Content-Type']) == 'Blah!'
    end
  end
end
