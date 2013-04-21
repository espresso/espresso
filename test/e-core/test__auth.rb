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
    Testing 'Basic via GET' do
      get :basic
      is(last_response).protected?

      authorize 'b', 'b'

      get :basic
      is(last_response).authorized?

      reset_basic_auth!

      get :basic
      is(last_response).protected?
    end

    Testing 'Basic via POST' do
      reset_basic_auth!

      post :basic
      is(last_response).protected?

      authorize 'b', 'b'

      post :basic
      is(last_response).authorized?

      reset_basic_auth!

      post :basic
      is(last_response).protected?
    end

    Testing 'Digest via GET' do

      reset_digest_auth!

      get :digest
      is(last_response).protected?

      digest_authorize 'd', 'd'

      get :digest
      is(last_response).authorized?

      reset_digest_auth!

      get :digest
      is(last_response).protected?
    end

    Testing 'Digest via POST' do

      reset_digest_auth!

      post :digest
      is(last_response).protected?

      digest_authorize 'd', 'd'

      post :digest
      is(last_response).authorized?

      reset_digest_auth!

      post :digest
      is(last_response).protected?
    end
  end

  class TokenAuth < E
    TOKEN = 'blah'.freeze
    REALM = 'API'.freeze

    before :without_options do
      token_auth do |token, options|
        token == TOKEN
      end
    end
    
    before :with_options do
      token_auth do |token, options|
        token == TOKEN && options[:realm] == REALM
      end
    end

    def index
      __method__
    end

    def without_options
      __method__
    end

    def with_options
      __method__
    end
  end

  Spec.new TokenAuth do
    get
    is(last_response).ok?
    is(last_response.body) == 'index'

    get :without_options
    is(last_response).protected?
    does(/HTTP Token/).match_body?
    does(/Access denied/).match_body?

    header['HTTP_AUTHORIZATION'] = EUtils.encode_token_auth_credentials(TokenAuth::TOKEN)
    get :without_options
    is(last_response).ok?
    is(last_response.body) == 'without_options'
    
    get :with_options
    is(last_response).protected?
    does(/HTTP Token/).match_body?
    does(/Access denied/).match_body?

    header['HTTP_AUTHORIZATION'] = EUtils.encode_token_auth_credentials(TokenAuth::TOKEN)
    get :with_options
    is(last_response).protected?
    does(/HTTP Token/).match_body?
    does(/Access denied/).match_body?

    header['HTTP_AUTHORIZATION'] = EUtils.encode_token_auth_credentials(TokenAuth::TOKEN, realm: TokenAuth::REALM)
    get :with_options
    is(last_response).ok?
    is(last_response.body) == 'with_options'
  end

end
