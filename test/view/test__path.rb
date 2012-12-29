module EViewTest__Path
  class App < E
    map '/path-test'
    layouts_path 'layouts'
    layout :base

    def index
      render
    end

    def render_test
      render path_to_templates('path-test/index.erb')
    end

    def render_partial_test
      render_p path_to_templates('path-test/partial.erb')
    end

    def render_layout_test
      render_l path_to_layouts('base.erb') do
        'blah'
      end
    end

    def adhoc_render_test
      render_erb path_to_templates('blah.erb')
    end
  end

  Spec.new App do

    get
    expect(last_response.body) == 'HEADER/index.erb'

    get :render_layout_test
    expect(last_response.body) == 'HEADER/blah'

    get :adhoc_render_test
    expect(last_response.body) == 'HEADER/blah.erb - adhoc_render_test'

    get :render_test
    expect(last_response.body) == 'HEADER/index.erb'

    get :render_partial_test
    expect(last_response.body) == 'PARTIAL'

  end
end
