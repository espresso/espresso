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

    Testing 404 do
      get :blah!
      is(last_response).not_found?
      is('NoLuckTryAgain - max params accepted: 0; params given: 1').current_body?
    end

    Testing 500 do
      get :raise_error
      is( 500).current_status?
      does(/FatalErrorOccurred: undefined local variable or method `code'/).match_body?

      get :json
      is( 500).current_status?
      does(/status\:0, error:undefined method `blah!'/).match_body?
    end
  end
end
