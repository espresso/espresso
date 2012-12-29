module EViewTest__ViewPrefix

  class App < E
    map '/path-test-i-dont-care'
    view_prefix '/path-test'
    layouts_path 'layouts'
    layout :base

    def index
      render
    end
  end

  class Nested < E
    map 'nested/templates'

    def index
      render
    end
  end

  class Canonical < E
    map '/', '/canonical-url'

    def index
      @greeting = "Hello!"
      render
    end
  end

  class Failure < E
    def tryme
      render
    end
  end

  Spec.new App do
    get
    expect(last_response.body) == 'HEADER/index.erb'
  end

  Spec.new Nested do
    get
    expect(last_response.body) == '/nested/templates/index.erb'
  end

  Spec.new Canonical do
    get
    expect(last_response.body) == 'Hello!'

    get 'canonical-url'
    expect(last_response.body) == 'Hello!'
  end

  Spec.new Failure do
    expect { get :tryme }.to_raise_error Errno::ENOENT
  end
end
