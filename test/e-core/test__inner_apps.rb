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

    Testing do
      get
      is('index').ok_body?

      %w[custom-module canonical].each do |url|
        get "#{url}"
        is('InnerApp').ok_body?
        is('custom').current_content_type?
      end
    end

  end
end
