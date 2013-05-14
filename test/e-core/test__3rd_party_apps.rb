module ECoreTest__3rdPartyApps

  App = Rack::Builder.new do
    map '/' do
      run lambda {|env| [200, {}, ['homePage']]}
    end
    map '/articles' do
      run lambda {|env| [200, {}, ['Articles']]}
    end
  end

  Spec.new self do

    Should 'respond to any request method and serve "/" path by default' do
      app E.new {
        mount App
      }

      get
      is(last_response).ok?
      is('homePage').ok_body?

      post
      is(last_response).ok?
      is('homePage').ok_body?

      get :articles
      is(last_response).ok?
      is('Articles').ok_body?

      put :articles
      is(last_response).ok?
      is('Articles').ok_body?
    end

    Should 'respond to given request methods only' do
      app E.new {
        mount App, on: :get
      }
      get
      is(last_response).ok?
      is('homePage').ok_body?

      post
      is(last_response).not_implemented?
    end

    Should 'mount into given root' do
      root = '/blog'
      app E.new {
        mount App, root
      }
      map root

      get
      is(last_response).ok?
      is('homePage').ok_body?

      get :articles
      is(last_response).ok?
      is('Articles').ok_body?
    end

    Ensure 'host politics honored' do
      host = 'fluffy.tld'
      app E.new {
        map host: host
        mount lambda { |env|
          if env['PATH_INFO'] =~ /\A\/?\Z/
            [200, {}, ['homePage']]
          end
        }
      }
      map '/'

      Should 'listen on default host' do
        get
        is(last_response).ok?
        is('homePage').ok_body?
      end

      Should 'listen on specified hosts' do
        header['HTTP_HOST'] = host
        get
        is(last_response).ok?
        is('homePage').ok_body?
      end

      Should 'reject requests originating on foreign hosts' do
        header['HTTP_HOST'] = 'evil.tld'
        get
        is(last_response).not_found?
      end

    end

  end
end
