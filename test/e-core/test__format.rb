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
    describe 'global setup' do

      it 'return html(default Content-Type)' do
        get
        is_content_type?('.html')
      end

      it 'returns xml' do
        get 'index.xml'
        is_content_type?('.xml')
      end

      it 'returns xsl' do
        get 'index.xsl'
        is_content_type?('.xsl')

        get 'some_action.xsl'
        is_content_type?('.xsl')
      end

      it 'returns 404 error' do
        get 'index.html'
        is_not_found?
      end
    end

    describe 'per-action setup' do
      it 'returns 404 error' do
        get 'api.xml'
        is_not_found?
        get 'api.html'
        is_not_found?
      end
      it 'returns json' do
        get 'api.json'
        is_content_type?('.json')
      end
      it 'returns html' do
        get 'api'
        is_content_type?('.html')
      end

      it 'overrides type set by format' do
        get :txt
        is_content_type?('.txt')
        get 'txt.xml'
        is_content_type?('.txt')
      end

    end

    it 'format disabler' do
      get :plain
      is_ok?

      get 'plain.xml'
      is_not_found?

      get 'plain.xsl'
      is_not_found?
    end

    describe 'by appending format to last param' do
      it do
        get :read, 'book.xml'
        is_body?'[:read, ".xml", "book"]'

        get :read, :book
        is_body? '[:read, nil, "book"]'
      end

      it 'that when format is passed with action, the format passed with last param has no effect' do
        get 'read.xml', 'book.xsl'
        is_body? '[:read, ".xml", "book.xsl"]'
      end
    end

  end
end