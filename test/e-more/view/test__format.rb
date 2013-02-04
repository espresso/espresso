module EMoreTest__View__Format
  class FormatTest < E
    map :format_test
    view_prefix base_url

    layout :layout__format

    format '.html', '.xml'
    format_for :api, '.json'
    format_for :string, '.str'

    setup '.str' do
      engine :String
      layout :layout__format
    end

    def index
      @greeting = 'Blah!'
      render
    end

    def api
      render_partial
    end

    def some___action
      render
    end

    def get_layout
      render_layout { format }
    end

    def named_layout layout
      render_layout(layout) { format }
    end

    def named template
      @greeting = __method__
      render_file template
    end

    def template template
      render do
        @greeting = __method__
        render_partial template
      end
    end

    def string
      layout false
      @string = 'blah!'
      render
    end

  end

  Spec.new FormatTest do

    Testing '`render` and `render_partial`' do

      Should 'render base template' do
        expect { get.body } == 'format-less layout/Blah!'
      end
      Should 'render .html template with .html layout' do
        expect { get('index.html').body } == '.html layout/.html template'
      end
      Should 'render .xml template with .html layout' do
        expect { get('index.xml').body } == '.xml layout/.xml template'
        is(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.xml')
      end
      Should 'render .json template without layout' do
        expect { get('api.json').body } == '.json'
        is(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.json')
      end
      Should 'raise error cause api.erb template is missing' do
        expect { get(:api).body }.to_raise_error Errno::ENOENT, /api\.erb/
      end
    end

    Testing '`render_layout`' do
      Should 'render/return html' do
        expect { get('layout.html').body } == '.html layout/.html'
      end
      Should 'render/return xml' do
        expect { get('layout.xml').body } == '.xml layout/.xml'
      end
      Should 'render format-less layout' do
        expect { get(:layout).body } == 'format-less layout/'
      end
    end

    Should 'use engine defined via setup' do
      get :string
      is?(last_response.body) == 'blah!'
      get 'string.str'
      is?(last_response.body) == '.str template - blah!'
    end

  end
end
