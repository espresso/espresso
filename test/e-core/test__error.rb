module ECoreTest__Error

  class App < E

    error 404 do
      'NoLuckTryAgain - '
    end

    error 500 do |e|
      action == :json ? "status:0, error:#{e}" : "FatalErrorOccurred: #{e}"
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

    it 404 do
      get :blah!
      is_not_found?
      is_body? 'NoLuckTryAgain - max params accepted: 0; params given: 1'
    end

    it 500 do
      get :raise_error
      is_status? 500
      is_body? /FatalErrorOccurred: undefined local variable or method `code'/

      get :json
      is_status? 500
      is_body? /status\:0, error:undefined method `blah!'/
    end
  end
end
