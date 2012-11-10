module EViewTest__RenderERB
  module App
    class Index < E
      map '/adhoc'
      layout :master
      view_path :templates
      layouts_path 'adhoc/layouts'
      format :html

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

      def layout 
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

      
      def inner__index
        render_erb Inner
      end

      def inner__partial
        render_erb_p Inner
      end

      def inner__given template
        render_erb Inner, template
      end

      def inner__given_partial template
        render_erb_p Inner, template
      end

      def inner__inline greeting
        @greeting = greeting
        render_erb Inner do
          "Hello World"
        end
      end

      def inner__inline_partial greeting
        @greeting = greeting
        render_erb_p Inner do
          "Hello World"
        end
      end

      def inner__layout
        render_erb_l Inner do
          "Hello World"
        end
      end

      def inner__given_layout template
        render_erb_l Inner, template do
          "Hello World"
        end
      end

      def inner__custom_layout
        render_erb Inner, :custom_layout
      end

    end

    class Inner < E
      map '/inner'
      engine :Haml
      view_path 'templates/adhoc'
      layouts_path :inner
      layout :layout
      format :xml

      setup :custom_layout do
        layout :layout_custom
      end

      def custom_layout
      end

    end
  end

  Spec.new App do
    app EApp.new { root File.expand_path '..', __FILE__ }.mount(App)
    map App::Index.base_url

    Testing 'current controller' do

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

          get :given, :tpl => '../../inner-templates/some-file'
          expect(last_response.body) == 'master layout - some-file.erb'

          Should 'render template as is, without computing format extension' do
            get 'given.html', :tpl => '../../inner-templates/some-file'
            expect(last_response.body) == 'master layout - some-file.erb'
          end
        end

        Should 'render without layout' do
          get :given_partial, :tpl => :partial
          is?(last_response.body) == 'given_partial'
          
          get 'given_partial.html', :tpl => :index
          is?(last_response.body) == 'given_partial.html'

          get :given_partial, :tpl => '../../inner-templates/some-file'
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
          is?(last_response.body) == 'master layout - Hello layout'
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

    Testing 'inner controller' do
      map App::Index.base_url + '/inner'

      Should 'render current action' do
        get :index
        check(last_response.body) == 'inner layout - inner__index'

        get :partial
        check(last_response.body) == 'inner__partial'
      end
      
      Should 'render given template' do
        get :given, :inner__index
        is?(last_response.body) == 'inner layout - inner__given'
        
        get :given_partial, :inner__partial
        is?(last_response.body) == 'inner__given_partial'
      end

      Testing 'inline rendering' do
        Should 'render with layout' do
          get :inline, :World
          is?(last_response.body) == 'inner layout - Hello World'
        end

        Should 'render without layout' do
          get :inline_partial, :World
          is?(last_response.body) == 'Hello World'
        end
      end

      Testing :render_layout do
        Should 'render the layout of current action' do
          get :layout
          is?(last_response.body) == 'inner layout - Hello World'
        end

        Should 'render given layout' do
          get :given_layout, :inner__layout
          is?(last_response.body) == 'inner layout - Hello World'
        end
      end

      Testing 'custom layout' do
        get :custom_layout
        check(last_response.body) == 'custom layout - inner__custom_layout'
      end

    end

  end
end
