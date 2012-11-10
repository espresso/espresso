module ECoreTest__Error

  class App < E

    error 404 do
      'NoLuckTryAgain'
    end

    error 500 do |e|
      'FatalErrorOccurred: %s' % e
    end

    setup :json do
      error 500 do |e|
        "status:0, error:#{e}"
      end
    end

    def index

    end

    def raise_error
      some risky code
    end

    def json
      blah!
    end

  end

  Spec.new App do

    Testing 404 do
      get :blah!
      expect(last_response.status) == 404
      is?(last_response.body) == 'NoLuckTryAgain'
    end

    Testing 500 do
      get :raise_error
      expect(last_response.status) == 500
      expect(last_response.body) =~ /FatalErrorOccurred: undefined local variable or method `code'/

      get :json
      expect(last_response.status) == 500
      expect(last_response.body) =~ /status\:0, error:undefined method `blah!'/
    end
  end
end
