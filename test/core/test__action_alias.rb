module ECoreTest__ActionAlias

  class AnyRequestMethod < E

    action_alias 'some-url', :endpoint
    action_alias 'some-another/url', :endpoint

    def index
    end

    def endpoint
    end
  end

  class SpecificRequestMethod < E

    action_alias 'some-url', :get_endpoint
    action_alias 'some-another/url', :get_endpoint

    def index
    end

    def get_endpoint
    end
  end

  class PrivateZone < E

    action_alias 'some-url', :private_method
    action_alias 'some-another/url', :private_method

    def index
    end

    protected
    def protected_method

    end
    private
    def private_method
    end
  end

  Spec.new AnyRequestMethod do

    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post url
      expect(last_response.status) == 200
    end

    get '/blah'
    expect(last_response.status) == 404

  end

  Spec.new SpecificRequestMethod do

    ['endpoint', 'some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post url
      expect(last_response.status) == 404
    end

    get '/blah'
    expect(last_response.status) == 404

  end

  Spec.new PrivateZone do

    ['some-url', 'some-another/url'].each do |url|
      get url
      expect(last_response.status) == 200

      post
      expect(last_response.status) == 200
    end

    %w(private_method protected_method blah).each do |m|
      get "/#{m}"
      expect(last_response.status) == 404
    end

  end

end
