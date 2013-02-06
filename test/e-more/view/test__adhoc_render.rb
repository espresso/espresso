module EMoreTest__View__AdhocRender
  class AdhocTest < E
    map '/adhoc_test'

    view_path 'templates'
    view_prefix base_url
    layout :master
    layouts_path 'adhoc_test/layouts'
    format '.html'

    setup :custom_layout do
      layout :custom
    end

    def index
      render_erb
    end

    def partial
      render_erb_p
    end

    def given
      render_erb params[:tpl]
    end

    def given_partial
      render_erb_p params[:tpl]
    end

    def inline greeting
      @greeting = greeting
      render_erb do
        "Hello <%= @greeting %>"
      end
    end

    def inline_partial greeting
      @greeting = greeting
      render_erb_p do
        "Hello <%= @greeting %>"
      end
    end

    def get_layout 
      render_erb_l do
        render_erb_p { "Hello <%= action %>" }
      end
    end

    def given_layout template
      render_erb_l template do
        @template = template
        render_erb_p { "Hello <%= @template %>" }
      end
    end

    def custom_layout
      render_erb
    end
  end

  Spec.new AdhocTest do

    Testing 'current action' do
      Should 'render with layout' do
        get
        is?(last_response.body) == 'master layout - index'
        
        get 'index.html'
        is?(last_response.body) == 'master layout - index.html'
      end

      Should 'render without layout' do
        get :partial
        is?(last_response.body) == 'partial'
        
        get 'partial.html'
        is?(last_response.body) == 'partial.html'
      end
    end

    Testing 'given template' do
      Should 'render with layout' do
        get :given, :tpl => :index
        is?(last_response.body) == 'master layout - given'

        Should 'compute format extension cause given template is actually an effective action' do
          get 'given.html', :tpl => :partial
          is?(last_response.body) == 'master layout - given.html'
        end

        get :given, :tpl => '../../custom-templates/some-file'
        expect(last_response.body) == 'master layout - some-file.erb'

        Should 'render template as is, without computing format extension' do
          get 'given.html', :tpl => '../../custom-templates/some-file'
          expect(last_response.body) == 'master layout - some-file.erb'
        end
      end

      Should 'render without layout' do
        get :given_partial, :tpl => :partial
        is?(last_response.body) == 'given_partial'
        
        get 'given_partial.html', :tpl => :index
        is?(last_response.body) == 'given_partial.html'

        get :given_partial, :tpl => '../../custom-templates/some-file'
        expect(last_response.body) == 'some-file.erb'
      end
    end

    Testing 'inline rendering' do
      Should 'render with layout' do
        get :inline, :World
        is?(last_response.body) == 'master layout - Hello World'
      end

      Should 'render without layout' do
        get :inline_partial, :World
        is?(last_response.body) == 'Hello World'
      end
    end

    Testing :render_layout do
      Should 'render the layout of current action' do
        get :layout
        is?(last_response.body) == 'master layout - Hello get_layout'
      end

      Should 'render given layout' do
        get :given_layout, :named
        is?(last_response.body) == 'named layout - Hello named'
      end
    end

    Testing 'custom layout' do
      get :custom_layout
      check(last_response.body) == 'custom layout - custom_layout'
    end

  end
end
