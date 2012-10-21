module ECoreTest__AppAuth

  class Foo < E
    map :/
    def index
      :Foo
    end
  end

  Spec.new self do

    app EApp.new {
      mount Foo
      auth { |u, p| [u, p] == ['b', 'b'] }
    }

    def protected?
      check { last_response.status } == 401
    end

    def authorized?
      check { last_response.status } == 200
    end

    Ensure 'existing controllers are Basic protected' do

      reset_basic_auth!

      get
      protected?

      authorize 'b', 'b'

      get
      authorized?

      reset_basic_auth!

      get
      protected?

      Ensure 'any location, existing or not, requested via any request method, are Basic protected' do
        reset_auth!

        get :foo
        is(protected?)

        post
        protected?

        head :blah
        protected?

        put :doh
        protected?
      end
    end

    app EApp.new {
      mount Foo
      digest_auth { |u| {'d' => 'd'}[u]  }
    }

    Ensure 'existing controllers are Digest protected' do

      reset_digest_auth!

      get
      protected?

      digest_authorize 'd', 'd'

      get
      authorized?

      reset_digest_auth!

      get
      protected?

      Ensure 'any location, existing or not, requested via any request method, are Digest protected' do
        reset_auth!
        
        get :foo
        is(protected?)

        post
        protected?

        head :blah
        protected?

        put :doh
        protected?
      end
    end

  end

end
