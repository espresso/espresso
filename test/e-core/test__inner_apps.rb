module ECoreTest__InnerApps

  class App < E
    map :/

    def index
      __method__
    end

  end

  InnerApp = lambda { |env| [200, {'Content-Type' => 'custom'}, ['InnerApp']] }

  Spec.new self do

    eapp = EApp.new do
      mount App
      mount InnerApp, '/custom-module', '/canonical'
    end
    app eapp

    testing do
      get
      is_ok_body? 'index'

      %w(custom-module canonical).each do |url|
        get "/#{url}"
        is_ok_body? 'InnerApp'
        is_content_type? 'custom'
      end
    end

  end
end
