module EViewTest__Relpath

  class App < E
    map '/'

    view_path :templates
    view_fullpath false
    layout :layout

    setup :get_render_layout_action do
      layout :layout__format
    end

    def index
      @greeting = 'World'
      render
    end

    def blah
      render
    end

    def given_action action
      render action.to_sym
    end

    def given_tpl
      render params[:tpl]
    end

    def given_partial
      render_p params[:tpl]
    end

    def get_render_layout_action action
      render_layout action.to_sym do
        action
      end
    end

    def get_render_layout_file
      file = params[:file]
      render_layout file do
        file
      end
    end

  end

  Spec.new self do
    app EApp.new { root File.expand_path '..', __FILE__ }.mount(App)

    get
    expect(last_response.body) == "Hello World!"

    get :blah
    expect(last_response.body) == "Hello blah.erb - blah!"

    get :given_action, :blah
    expect(last_response.body) == "Hello blah.erb - given_action!"

    get :given_tpl, :tpl => :partial
    expect(last_response.body) == "Hello partial!"
    
    get :given_tpl, :tpl => '../inner-templates/some-file'
    expect(last_response.body) == "Hello some-file.erb!"

    get :given_partial, :tpl => '../inner-templates/some_partial'
    expect(last_response.body) == "some_partial.erb"

    get :render_layout_action, :get_render_layout_action
    expect(last_response.body) == "format-less layout/get_render_layout_action"

    get :render_layout_file, :file => :layout__format
    expect(last_response.body) == "format-less layout/layout__format"

    get :render_layout_file, :file => '../inner-templates/layout'
    expect(last_response.body) =~ /header.*\.\.\/inner-templates\/layout.*footer/m

  end
end
