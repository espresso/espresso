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

    get
    expect(last_response.status) == 200
    expect(last_response.body) == 'index'

    get '/custom-module'
    expect(last_response.status) == 200
    expect(last_response.body) == 'InnerApp'
    expect(last_response['Content-Type']) == 'custom'

    get '/canonical'
    expect(last_response.status) == 200
    expect(last_response.body) == 'InnerApp'
    expect(last_response['Content-Type']) == 'custom'

  end
end
