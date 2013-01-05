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
    Describe 'global setup' do

      It 'returns html(default Content-Type)' do
        get
        is('.html').current_content_type?
      end

      It 'returns xml' do
        get 'index.xml'
        is('.xml').current_content_type?
      end

      It 'returns xsl' do
        get 'index.xsl'
        is('.xsl').current_content_type?

        get 'some_action.xsl'
        is('.xsl').current_content_type?
      end

      It 'returns 404 error' do
        get 'index.html'
        is(last_response).not_found?
      end
    end

    Describe 'per-action setup' do
      It 'returns 404 error' do
        get 'api.xml'
        is(last_response).not_found?
        get 'api.html'
        is(last_response).not_found?
      end
      It 'returns json' do
        get 'api.json'
        is('.json').current_content_type?
      end
      It 'returns html' do
        get 'api'
        is('.html').current_content_type?
      end

      It 'overrides type set by format' do
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

    Describe 'by appending format to last param' do
      Testing do
        get :read, 'book.xml'
        is('[:read, ".xml", "book"]').current_body?

        get :read, :book
        is('[:read, nil, "book"]').current_body?
      end

      Testing 'that when format is passed with action, the format passed with last param has no effect' do
        get 'read.xml', 'book.xsl'
        is('[:read, ".xml", "book.xsl"]').current_body?
      end
    end

  end
end
