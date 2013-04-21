class E

  # @example protecting all actions via Basic authorization
  #    auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #
  # @example protecting only :edit action
  #    setup :edit do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @example protecting only :edit and :delete actions
  #    setup :edit, :delete do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @params [Hash] opts
  # @option opts [String] :realm
  #   default - AccessRestricted
  # @param [Proc] proc
  #
  def basic_auth opts = {}, &proc
    __e__authorize! Rack::Auth::Basic, opts[:realm] || 'AccessRestricted', &proc
  end
  alias auth basic_auth
  define_setup_method :auth
  define_setup_method :basic_auth

  # @example digest auth - hashed passwords:
  #    # hash the password somewhere in irb:
  #    # ::Digest::MD5.hexdigest 'admin:AccessRestricted:somePassword'
  #    #                   username ^      realm ^       password ^
  #
  #    #=> 9d77d54decc22cdcfb670b7b79ee0ef0
  #
  #    digest_auth :passwords_hashed => true, :realm => 'AccessRestricted' do |user|
  #      {'admin' => '9d77d54decc22cdcfb670b7b79ee0ef0'}[user]
  #    end
  #
  # @example digest auth - plain password
  #    digest_auth do |user|
  #      {'admin' => 'password'}[user]
  #    end
  #
  # @params [Hash] opts
  # @option opts [String] :realm
  #   default - AccessRestricted
  # @option opts [String] :opaque
  #   default - same as realm
  # @option opts [Boolean] :passwords_hashed
  #   default - false
  # @param [Proc] proc
  #
  def digest_auth opts = {}, &proc
    opts[:realm]  ||= 'AccessRestricted'
    opts[:opaque] ||= opts[:realm]
    __e__authorize! Rack::Auth::Digest::MD5, *[opts], &proc
  end
  define_setup_method :digest_auth

  # Makes it dead easy to do HTTP Token authentication.
  #
  # @example simple Token example
  #
  #   class App < E
  #     TOKEN = "secret".freeze
  #
  #     setup :edit do
  #       token_auth { |token| token == TOKEN }
  #     end
  #
  #     def index
  #       "Everyone can see me!"
  #     end
  #
  #     def edit
  #       "I'm only accessible if you know the password"
  #     end
  #
  #   end
  #
  #
  # @example  more advanced Token example
  #           where only Atom feeds and the XML API is protected by HTTP token authentication,
  #           the regular HTML interface is protected by a session approach
  #
  #   class App < E
  #     before :set_account do
  #       authenticate
  #     end
  #
  #     def set_account
  #       @account = Account.find_by ...
  #     end
  #
  #     private
  #     def authenticate
  #       if accept? /xml|atom/
  #         if user = valid_token_auth? { |t, o| @account.users.authenticate(t, o) }
  #           @current_user = user
  #         else
  #           request_token_auth!
  #         end
  #       else
  #         # session based authentication
  #       end
  #     end
  #   end
  #
  # In your integration tests, you can do something like this:
  #
  #   def test_access_granted_from_xml
  #     get(
  #       "/notes/1.xml", nil,
  #       'HTTP_AUTHORIZATION' => EUtils.encode_token_auth_credentials('some-token')
  #     )
  #
  #     assert_equal 200, status
  #   end
  #
  # On shared hosts, Apache sometimes doesn't pass authentication headers to
  # FCGI instances. If your environment matches this description and you cannot
  # authenticate, try this rule in your Apache setup:
  #
  #   RewriteRule ^(.*)$ dispatch.fcgi [E=X-HTTP_AUTHORIZATION:%{HTTP:Authorization},QSA,L]
  #
  def token_auth realm = 'Application', &proc
    validate_token_auth(&proc) || request_token_auth(realm)
  end
  define_setup_method :token_auth

  def validate_token_auth &proc
    ETokenAuth.new(self).validate_token_auth(&proc)
  end
  alias valid_token_auth? validate_token_auth

  def request_token_auth realm = 'Application'
    ETokenAuth.new(self).request_token_auth(realm)
  end
  alias request_token_auth! request_token_auth

  private
  def __e__authorize! auth_class, *auth_args, &auth_proc
    if auth_required = auth_class.new(proc {}, *auth_args, &auth_proc).call(env)
      halt auth_required
    end
  end
end

class ETokenAuth # borrowed from Rails and adapted to Espresso needs
  TOKEN_REGEX = /^Token /
  AUTHN_PAIR_DELIMITERS = /(?:,|;|\t+)/

  def initialize controller_instance
    @controller_instance = controller_instance
  end

  # If token Authorization header is present,
  # call the given proc with the present token and options.
  #
  # @param [Proc] proc
  #   Proc to call if a token is present. The Proc should take two arguments:
  #
  #     validate_token_auth { |token, options| ... }
  #
  # @return the return value of `proc` if a token is found
  # @return `nil` if no token found
  def validate_token_auth &proc
    token, options = token_and_options
    token && token.size > 0 && proc.call(token, options)
  end

  # Sets a WWW-Authenticate and halt to let the client know a token is required.
  #
  # @param [String] realm - realm to use in the header
  #
  def request_token_auth(realm)
    @controller_instance.response[EConstants::HEADER__AUTHENTICATE] = \
      EUtils.encode_token_auth_credentials(realm: realm.delete('"'))
    @controller_instance.halt(EConstants::STATUS__PROTECTED, "HTTP Token: Access denied.\n")
  end

  private
  # Parses the token and options out of the token authorization header. If
  # the header looks like this:
  #   Authorization: Token token="abc", nonce="def"
  # Then the returned token is "abc", and the options is {nonce: "def"}
  #
  # @param [ERequest] request - ERequest instance with the current env
  #
  # @return an Array of [String, Hash] if a token is present
  # @return nil if no token found
  def token_and_options
    return unless authorization_key = EConstants::ENV__AUTHORIZATION_KEYS.find do |key|
      @controller_instance.env.has_key?(key)
    end
    authorization_request = @controller_instance.env[authorization_key].to_s
    if authorization_request[TOKEN_REGEX]
      params = token_params_from(authorization_request)
      [params.shift.last, EUtils.indifferent_params(Hash[params])]
    end
  end

  def token_params_from(auth)
    rewrite_param_values params_array_from(raw_params(auth))
  end

  # Takes raw_params and turns it into an array of parameters
  def params_array_from(raw_params)
    raw_params.map { |param| param.split %r/=(.+)?/ }
  end

  # This removes the `"` characters wrapping the value.
  def rewrite_param_values(array_params)
    array_params.each { |param| param.last.gsub! %r/^"|"$/, '' }
  end

  # This method takes an authorization body and splits up the key-value
  # pairs by the standardized `:`, `;`, or `\t` delimiters defined in
  # `AUTHN_PAIR_DELIMITERS`.
  def raw_params(auth)
    auth.sub(TOKEN_REGEX, '').split(/"\s*#{AUTHN_PAIR_DELIMITERS}\s*/)
  end

end
