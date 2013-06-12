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

    Testing 'global setup' do

      Should 'return html(default Content-Type)' do
        get
        is('.html').current_content_type?
      end

      Should 'return xml' do
        get 'index.xml'
        is('.xml').current_content_type?
      end

      Should 'return xsl' do
        get 'index.xsl'
        is('.xsl').current_content_type?

        get 'some_action.xsl'
        is('.xsl').current_content_type?
      end

      Should 'returns error' do
        get 'index.html'
        is(last_response).not_found?
      end
    end

    Testing 'per-action setup' do
      Should 'return 404 error' do
        get 'api.xml'
        is(last_response).not_found?
        get 'api.html'
        is(last_response).not_found?
      end
      Should 'return json' do
        get 'api.json'
        is('.json').current_content_type?
      end
      Should 'return html' do
        get 'api'
        is('.html').current_content_type?
      end

      Should 'override type set by format' do
        get :txt
        is('.txt').current_content_type?
        get 'txt.xml'
        is('.txt').current_content_type?
      end

    end

    Testing 'format disabler' do
      get :plain
      is(last_response).ok?

      get 'plain.xml'
      is(last_response).not_found?

      get 'plain.xsl'
      is(last_response).not_found?
    end

    Testing 'by appending format to last param' do
      Testing do
        get :read, 'book.xml'
        is('[:read, ".xml", "book"]').current_body?

        get :read, :book
        is('[:read, nil, "book"]').current_body?
      end

      Should 'return 404 if something passed after format' do
        get 'read.xml/something'
        is(last_response).not_found?
      end
    end

  end
end
