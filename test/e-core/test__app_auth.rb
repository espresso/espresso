module ECoreTest__AppAuth

  class Foo < E
    map :/
    def index
      :Foo
    end
  end

  Spec.new self do

    app E.new {
      mount Foo
      auth { |u, p| [u, p] == ['b', 'b'] }
    }

    Describe 'existing controllers are Basic protected' do
      Testing do
        reset_basic_auth!

        get
        is(last_response).protected?

        authorize 'b', 'b'

        get
        is(last_response).authorized?

        reset_basic_auth!

        get
        is(last_response).protected?
      end

      Testing 'any location, existing or not, requested via any request method, are Basic protected' do
        reset_auth!

        get :foo
        is(last_response).protected?

        post
        is(last_response).protected?

        head :blah
        is(last_response).protected?

        put :doh
        is(last_response).protected?
      end
    end

    app E.new {
      mount Foo
      digest_auth { |u| {'d' => 'd'}[u]  }
    }

    Describe 'existing controllers are Digest protected' do
      Testing do
        reset_digest_auth!

        get
        is(last_response).protected?

        digest_authorize 'd', 'd'

        get
        is(last_response).authorized?

        reset_digest_auth!

        get
        is(last_response).protected?
      end

      Testing 'any location, existing or not, requested via any request method, are Digest protected' do
        reset_auth!

        get :foo
        is(last_response).protected?

        post
        is(last_response).protected?

        head :blah
        is(last_response).protected?

        put :doh
        is(last_response).protected?
      end
    end

  end

end
