module EViewTest__Path
  class App < E
    map '/path-test'
    layouts_path 'layouts'
    layout :base

    def index
      render
    end

    def render_test
      render view_path('path-test/index')
    end

    def render_partial_test
      render_p view_path('path-test/partial')
    end

    def render_layout_test
      render_l layouts_path('base') do
        'blah'
      end
    end

    def adhoc_render_test
      render_erb view_path('blah')
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
