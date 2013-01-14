module ECoreTest__ActionAlias

  class AnyRequestMethod < E
    map '/', '/some-canonical'

    action_alias 'some-url', :endpoint
    action_alias 'some-another/url', :endpoint

    def index
    end

    def endpoint
    end
  end

  class SpecificRequestMethod < E
    map '/', '/some-canonical'

    action_alias 'some-url', :get_endpoint
    action_alias 'some-another/url', :get_endpoint

    def index
    end

    def get_endpoint
    end
  end

  class PrivateZone < E

    action_alias 'protected_alias', :protected_method
    action_alias 'private_alias',   :private_method

    def index
    end

    protected
    def protected_method
    end

    private
    def private_method
    end
  end

  class AppCanonicals < E
    map '/', '/some-canonical'

    action_alias 'some-url', :endpoint
    action_alias 'some-another/url', :endpoint

    def index
    end

    def endpoint
    end
  end

  Spec.new AnyRequestMethod do
  
    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      is(last_response).ok?

      post url
      is(last_response).ok?
    end

    Testing :canonicals do
      ['some-canonical/some-url', 'some-canonical/some-another/url'].each do |url|
        get url
        is(last_response).ok?

        post url
        is(last_response).ok?
      end
    end

    get '/blah'
    is(last_response).not_found?
    
  end

  Spec.new SpecificRequestMethod do

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
    app EApp.new.mount(AppCanonicals, '/', '/app-canonical')
    map AppCanonicals.base_url

    ['app-canonical/some-url', 'app-canonical/some-another/url'].each do |url|
      get url
      is(last_response).ok?
    end

  end

end
