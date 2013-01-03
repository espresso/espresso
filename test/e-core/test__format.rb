module ECoreTest__Format

  class App < E

    format '.xml', '.xsl'
    format_for :api, '.json'
    disable_format_for :plain

    def index
    end

    def some_action
    end

    def api
    end

    def txt
      content_type '.txt'
    end

    def read item
      [action, format, item].inspect
    end

    def plain
    end

  end

  Spec.new App do

    def of_type? response, type
      check(response.header['Content-Type']) == 
        Rack::Mime::MIME_TYPES.fetch(type)
    end

    Testing 'global setup' do

      Should 'return html(default Content-Type)' do
        get
        is(last_response).of_type?('.html')
      end

      Should 'return xml' do
        get 'index.xml'
        is(last_response).of_type?('.xml')
      end

      Should 'return xsl' do
        get 'index.xsl'
        is(last_response).of_type?('.xsl')

        get 'some_action.xsl'
        is(last_response).of_type?('.xsl')
      end

      Should 'return 404 error' do
        get 'index.html'
        is?(last_response.status) == 404
      end
    end

    Testing 'per-action setup' do
      Should 'return 404 error' do
        get 'api.xml'
        is?(last_response.status) == 404
        get 'api.html'
        is?(last_response.status) == 404
      end
      Should 'return json' do
        get 'api.json'
        is(last_response).of_type?('.json')
      end
      Should 'return html' do
        get 'api'
        is(last_response).of_type?('.html')
      end

      Should 'override type set by format' do
        get :txt
        is(last_response).of_type?('.txt')
        get 'txt.xml'
        is(last_response).of_type?('.txt')
      end

    end

    Testing 'format disabler' do
      get :plain
      expect(last_response.status) == 200

      get 'plain.xml'
      expect(last_response.status) == 404
      
      get 'plain.xsl'
      expect(last_response.status) == 404
    end

    Testing 'by appending format to last param' do

      get :read, 'book.xml'
      expect(last_response.body) == '[:read, ".xml", "book"]'

      get :read, :book
      expect(last_response.body) == '[:read, nil, "book"]'

      Ensure 'that when format is passed with action, the format passed with last param has no effect' do
        get 'read.xml', 'book.xsl'
        expect(last_response.body) == '[:read, ".xml", "book.xsl"]'
      end
    end
    
  end
end
