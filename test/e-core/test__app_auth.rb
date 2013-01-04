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

    describe 'existing controllers are Basic protected' do
      testing do
        reset_basic_auth!

        get
        protected?

        authorize 'b', 'b'

        get
        authorized?

        reset_basic_auth!

        get
        protected?
      end

      testing 'any location, existing or not, requested via any request method, are Basic protected' do
        reset_auth!

        get :foo
        protected?

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

    describe 'existing controllers are Digest protected' do
      testing do
        reset_digest_auth!

        get
        protected?

        digest_authorize 'd', 'd'

        get
        authorized?

        reset_digest_auth!

        get
        protected?
      end

      testing 'any location, existing or not, requested via any request method, are Digest protected' do
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
