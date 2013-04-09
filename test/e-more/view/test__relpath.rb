module EMoreTest__View__Relpath

  class RelpathTest < E
    map :relpath_test
    view_prefix base_url

    view_path 'templates'
    view_fullpath false
    layout :layout

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

    def get_render_layout
      file = params[:file]
      render_layout file do
        file
      end
    end
  end

  Spec.new self do
    app E.new {
      root File.expand_path '..', __FILE__
    }.mount(RelpathTest)
    map RelpathTest.base_url

    get
    expect(last_response.body) == "Hello World!"

    get :blah
    expect(last_response.body) == "Hello blah.erb - blah!"

    get :given_action, :blah
    expect(last_response.body) == "Hello blah.erb - given_action!"

    get :given_tpl, :tpl => :partial
    expect(last_response.body) == "Hello partial!"
    
    get :given_tpl, :tpl => '../../custom-templates/some-file'
    expect(last_response.body) == "Hello some-file.erb!"

    get :given_partial, :tpl => '../../custom-templates/some_partial'
    expect(last_response.body) == "some_partial.erb"

    get :render_layout, :file => :layout__format
    expect(last_response.body) == "format-less layout/layout__format"

    get :render_layout, :file => '../custom-templates/layout'
    expect(last_response.body) =~ /header.*\.\.\/custom-templates\/layout.*footer/m

  end
end
