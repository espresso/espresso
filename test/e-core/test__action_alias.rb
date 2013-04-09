module ECoreTest__ActionAlias

  class App < E
    map '/', '/some-canonical'

    alias_action 'some-url',         :get_endpoint
    alias_action 'some-another/url', :get_endpoint

    def index
    end

    def get_endpoint
    end
  end

  class PrivateZone < E

    alias_action 'protected_alias', :protected_method
    alias_action 'private_alias',   :private_method

    def index
    end

    protected
    def protected_method
    end

    private
    def private_method
    end
  end

  class CanonicalsApp < E
    map '/', '/some-canonical'

    alias_action 'some-url', :endpoint
    alias_action 'some-another/url', :endpoint

    def index
    end

    def endpoint
    end
  end

  Spec.new App do

    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      is(last_response).ok?

      post url
      is(last_response).not_implemented?
    end

    Testing :canonicals do
      ['some-canonical/some-url', 'some-canonical/some-another/url'].each do |url|
        get url
        is(last_response).ok?

        post url
        is(last_response).not_implemented?
      end
    end

    get '/blah'
    is(last_response).not_found?
  end

  Spec.new PrivateZone do

    ['protected_alias', 'private_alias'].each do |url|
      get url
      is(last_response).ok?
    end

    Ensure 'protected and private methods becomes public' do
      %w[protected_method private_method].each do |url|
        get url
        is(last_response).ok?
      end
    end
  end

  Spec.new self do
    app E.new.mount(CanonicalsApp, '/', '/app-canonical')
    map CanonicalsApp.base_url

    ['app-canonical/some-url', 'app-canonical/some-another/url'].each do |url|
      get url
      is(last_response).ok?
    end

  end

end
