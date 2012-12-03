module EViewTest__Format
  class App < E
    map '/'

    layout :layout__format

    format :html, :xml
    setup :api do
      format :json
    end

    setup :string do
      format :str
    end

    setup '.str' do
      engine :String
      engine_ext :str
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

    def action_by_format
      render (params[:action] || action).to_s + params[:format]
    end

    def get_layout
      render_layout { format }
    end

    def named_layout layout
      render_layout(layout) { format }
    end

    def named action
      @greeting = __method__
      render action.to_sym
    end

    def template template
      render do
        @greeting = __method__
        render_partial template
      end
    end

    def string
      @string = 'blah!'
      render
    end

  end

  Spec.new App do

    Testing '`render` and `render_partial`' do

      Should 'render base template' do
        expect { get('index').body } == 'format-less layout/Blah!'
      end
      Should 'render html template' do
        expect { get('index.html').body } == 'format-less layout/.html template'
      end
      Should 'render xml template' do
        expect { get('index.xml').body } == 'format-less layout/.xml template'
        is(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.xml')
      end
      Should 'render json template' do
        expect { get('api.json').body } == '.json'
        is(last_response.header['Content-Type']) == Rack::Mime::MIME_TYPES.fetch('.json')
      end
      Should 'raise error cause :api action has no format-less template' do
        expect { get(:api).body }.to_raise_error Errno::ENOENT
      end

      Should 'ignore format when named action rendered' do
        is?(get('named.html', :index).body) == 'format-less layout/named'
        is?(get('named.xml', :some___action).body) == 'format-less layout/named'
      end

      Should 'ignore format when arbitrary template rendered' do
        is?(get('template.html', :index).body) == 'format-less layout/template'
        is?(get('template.xml', 'some___action').body) == 'format-less layout/template'
        is?(get(:template, 'api.json').body) == 'format-less layout/'
      end

      Should 'correctly resolve path(and use the layout of rendered action) when action provided with format' do
        When 'rendering current action' do
          expect { get(:action_by_format, :format => '.html').body } == 'format-less layout/.html template of :action_by_format action'
          expect { get(:action_by_format, :format => '.xml').body } == 'format-less layout/.xml template of :action_by_format action'
        end
        And 'when rendering a given action' do
          expect { get(:action_by_format, :action => 'index', :format => '.html').body } == 'format-less layout/.html template'
          expect { get(:action_by_format, :action => 'index', :format => '.xml').body } == 'format-less layout/.xml template'
        end
      end
    end

    Testing '`render_layout`' do

      Should 'render/return html' do
        expect { get('layout.html').body } == 'format-less layout/.html'
      end
      Should 'render/return xml' do
        expect { get('layout.xml').body } == 'format-less layout/.xml'
      end
      Should 'render format-less layout' do
        expect { get(:layout).body } == 'format-less layout/'
      end

      Should 'ignore format when named layout rendered' do
        is?(get('named_layout.html', :layout).body) == 'Hello .html!'
        is?(get('named_layout.html', 'layout__format.xml').body) == '.xml layout/.html'
        is?(get('named_layout.xml', 'layout__format.html').body) == '.html layout/.xml'
      end
    end

    Testing 'custom engine' do
      get :string
      is?(last_response.body) == 'format-less layout/blah!'
      get 'string.str'
      is?(last_response.body) == '.str layout/.str template - blah!'
    end

  end
end
