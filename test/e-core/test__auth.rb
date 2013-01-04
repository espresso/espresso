module ECoreTest__Auth

  class App < E

    setup :basic, :post_basic do
      auth { |u, p| [u, p] == ['b', 'b'] }
    end

    setup :digest, :post_digest do
      digest_auth { |u| {'d' => 'd'}[u] }
    end

    def basic
      action
    end

    def digest
      action
    end

    def post_basic
      action
    end

    def post_digest
      action
    end
  end

  Spec.new App do
    testing 'Basic via GET' do
      get :basic
      protected?

      authorize 'b', 'b'

      get :basic
      authorized?

      reset_basic_auth!

      get :basic
      protected?
    end

    testing 'Basic via POST' do
      reset_basic_auth!

      post :basic
      protected?

      authorize 'b', 'b'

      post :basic
      authorized?

      reset_basic_auth!

      post :basic
      protected?
    end

    testing 'Digest via GET' do

      reset_digest_auth!

      get :digest
      protected?

      digest_authorize 'd', 'd'

      get :digest
      authorized?

      reset_digest_auth!

      get :digest
      protected?
    end

    testing 'Digest via POST' do

      reset_digest_auth!

      post :digest
      protected?

      digest_authorize 'd', 'd'

      post :digest
      authorized?

      reset_digest_auth!

      post :digest
      protected?
    end
  end

end
