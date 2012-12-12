class << E
  # @example restricting all actions using Basic authorization:
  #    auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #
  # @example restricting only :edit action:
  #    setup :edit do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @example restricting only :edit and :delete actions:
  #    setup :edit, :delete do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @params [Hash] opts
  # @option opts [String] :realm
  #   default - AccessRestricted
  # @param [Proc] proc
  def basic_auth opts = {}, &proc
    add_restriction true, :basic, opts, &proc
  end
  alias auth basic_auth

  def basic_auth! opts = {}, &proc
    add_restriction false, :basic, opts, &proc
  end
  alias auth! basic_auth!

  # @example digest auth - hashed passwords:
  #    # hash the password somewhere in irb:
  #    # ::Digest::MD5.hexdigest 'user:AccessRestricted:somePassword'
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
  def digest_auth opts = {}, &proc
    add_restriction true, :digest, opts, &proc
  end

  def digest_auth! opts = {}, &proc
    add_restriction false, :digest, opts, &proc
  end

  def restrictions? action = nil
    return unless @restrictions
    action ?
        @restrictions[action] || @restrictions[:*] :
        @restrictions
  end

  # Content-Type to be returned by action(s). default is text/html
  #
  # @example - all actions should return text/javascript
  #    content_type ".js"
  #
  # @example - :feed should return application/rss+xml
  #    setup :feed do
  #      content_type ".rss"
  #    end
  #
  # Content-Type can also be set at instance level.
  # see `#content_type!`
  #
  # @param [String] content_type
  def content_type content_type
    content_type! content_type, true
  end
  alias provide content_type

  def content_type! content_type, keep_existing = false
    return if locked?
    content_type?
    setup__actions.each do |a|
      next if @content_type[a] && keep_existing
      @content_type[a] = content_type
    end
  end
  alias provide! content_type!

  def content_type? action = nil
    @content_type ||= {}
    @content_type[action] || @content_type[:*]
  end

  # update Content-Type header by add/update charset.
  #
  # @note please make sure that returned body is of same charset,
  #       cause `charset` will only set header and not change the charset of body itself!
  #
  # @param [String] charset
  #   when class is yet open for configuration, first arg is treated as charset to be set.
  #   otherwise it is treated as action to query charset for.
  def charset charset
    charset! charset, true
  end

  def charset! charset, keep_existing = false
    return if locked?
    charset?
    setup__actions.each do |a|
      next if @charset[a] && keep_existing
      @charset[a] = charset
    end
  end

  def charset? action = nil
    @charset ||= {}
    @charset[action] || @charset[:*]
  end

  # Control content freshness by setting Cache-Control header.
  #
  # It accepts any number of params in form of directives and/or values.
  #
  # Directives:
  #
  # *   :public
  # *   :private
  # *   :no_cache
  # *   :no_store
  # *   :must_revalidate
  # *   :proxy_revalidate
  #
  # Values:
  #
  # *   :max_age
  # *   :min_stale
  # *   :s_max_age
  #
  # @example
  #
  # cache_control :public, :must_revalidate, :max_age => 60
  # => Cache-Control: public, must-revalidate, max-age=60
  #
  # cache_control :public, :must_revalidate, :proxy_revalidate, :max_age => 500
  # => Cache-Control: public, must-revalidate, proxy-revalidate, max-age=500
  #
  def cache_control *args
    cache_control! *args << true
  end

  def cache_control! *args
    return if locked? || args.empty?
    cache_control?
    keep_existing = args.delete(true)
    setup__actions.each do |a|
      next if @cache_control[a] && keep_existing
      @cache_control[a] = args
    end
  end

  def cache_control? action = nil
    @cache_control ||= {}
    @cache_control[action] || @cache_control[:*]
  end

  # Set Expires header and update Cache-Control
  # by adding directives and setting max-age value.
  #
  # First argument is the value to be added to max-age value.
  #
  # It can be an integer number of seconds in the future or a Time object
  # indicating when the response should be considered "stale".
  #
  # @example
  #
  # expires 500, :public, :must_revalidate
  # => Cache-Control: public, must-revalidate, max-age=500
  # => Expires: Mon, 08 Jun 2009 08:50:17 GMT
  #
  def expires *args
    expires! *args << true
  end

  def expires! *args
    return if locked?
    expires?
    keep_existing = args.delete(true)
    setup__actions.each do |a|
      next if @expires[a] && keep_existing
      @expires[a] = args
    end
  end

  def expires? action = nil
    @expires ||= {}
    @expires[action] || @expires[:*]
  end

  # define callbacks to be executed on HTTP errors.
  #
  # @example handle 404 errors:
  #    class App < E
  #
  #      error 404 do |error_message|
  #        "Some weird error occurred: #{ error_message }"
  #      end
  #    end
  # @param [Integer] code
  # @param [Proc] proc
  def error code, &proc
    error! code, :keep_existing, &proc
  end

  def error! code, keep_existing = nil, &proc
    return if locked?
    error? code
    raise('please provide a proc to be executed on errors') unless proc
    method = proc_to_method :http, :error_procs, code, &proc
    setup__actions.each do |a|
      next if @error_handlers[code][a] && keep_existing
      @error_handlers[code][a] = [method, instance_method(method).arity]
    end
  end

  def error? code, action = nil
    (@error_handlers ||= {})[code] ||= {}
    @error_handlers[code][action] || @error_handlers[code][:*]
  end

  # @api semi-public
  #
  # remap served root(s) by prepend given path to controller's root and canonical paths
  #
  # @note Important: all actions should be defined before re-mapping occurring
  #
  def remap! root, *canonicals
    return if locked?
    base_url = root.to_s + '/' + base_url()
    new_canonicals = [] + canonicals
    canonicals().each do |ec|
      # each existing canonical should be prepended with new root
      new_canonicals << base_url + '/' + ec.to_s
      # as well as with each given canonical
      canonicals.each do |gc|
        new_canonicals << gc.to_s + '/' + ec.to_s
      end
    end
    map base_url, *new_canonicals
  end

  def global_setup! &setup
    return unless setup
    @global_setup = true
    setup.arity == 1 ?
        self.class_exec(self, &setup) :
        self.class_exec(&setup)
    setup!
    @global_setup = false
  end

  def global_setup?
    @global_setup
  end

  def session(*)
    raise 'Please use `%s` at app level only' % __method__
  end

  def rewrite(*)
    raise 'Please use `%s` at app level only' % __method__
  end
  alias rewrite_rule rewrite

  private

  def add_restriction keep_existing, type, opts = {}, &proc
    return if locked? || proc.nil?
    @restrictions ||= {}
    args = []
    case type
      when :basic
        cls = ::Rack::Auth::Basic
        args << (opts[:realm] || 'AccessRestricted')
      when :digest
        cls = ::Rack::Auth::Digest::MD5
        opts[:realm]  ||= 'AccessRestricted'
        opts[:opaque] ||= opts[:realm]
        args = [opts]
      else
        raise 'wrong auth type: %s' % type.inspect
    end
    setup__actions.each do |a|
      next if @restrictions[a] && keep_existing
      @restrictions[a] = [cls, args, proc]
    end
  end

  # instance_exec at runtime is expensive enough,
  # so compiling procs into methods at load time.
  def proc_to_method *chunks, &proc
    chunks += [self.to_s, proc.to_s]
    name = ('__appetite__e__%s__' %
        chunks.map { |s| s.to_s }.join('_').gsub(/[^\w|\d]/, '_')).to_sym
    define_method name, &proc
    name
  end

end
