module EMoreTest__View__ViewPrefix

  class App < E
    map '/path-test-i-dont-care'
    view_prefix '/path_test'
    layouts_path 'layouts'
    layout :base

    def index
      render
    end
  end

  Spec.new App do
    get
    expect(last_response.body) == 'HEADER/index.erb'
  end

  class CanonicalTest < E
    map '/canonical_test', '/canonical-url'
    view_prefix base_url

    def index
      @greeting = "Hello!"
      render
    end
  end

  Spec.new CanonicalTest do
    get
    expect(last_response.body) == 'Hello!'

    get '/canonical-url'
    expect(last_response.body) == 'Hello!'
  end

  VIEW_PATH = File.expand_path('../templates', __FILE__)
  class Default < E
    view_fullpath VIEW_PATH

    def index
      render
    end
  end

  Spec.new self do
    app E.new.mount(Default)
    map Default.base_url

    get
    is(last_response).ok?
    expect(last_response.body) == 
      VIEW_PATH + "/e_more_test__view__view_prefix/default/index.erb"
  end

  class Nested
    class App < E
      view_fullpath VIEW_PATH

      def index
        render
      end
    end
  end

  Spec.new self do
    app E.new.mount(Nested::App)
    map Nested::App.base_url

    get
    is(last_response).ok?
    expect(last_response.body) ==
      VIEW_PATH + "/e_more_test__view__view_prefix/nested/app/index.erb"
  end

end
