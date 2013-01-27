class E

  # set/get or update Content-Type header.
  #
  # if no args given, actual Content-Type returned.
  #
  # To set charset alongside Content-Type, use :charset option.
  #
  # @example all actions matching /api/ will return JSON Content-Type
  #   class App < E
  #
  #     setup /api/ do
  #       content_type '.json'
  #     end
  #
  #     # ...
  #   end
  # @param [Array] args
  #
  def content_type *args
    return response[HEADER__CONTENT_TYPE] if args.empty?
    type, opts = nil, {}
    args.each {|a| a.is_a?(Hash) ? opts.update(a) : type = a}
    if type
      type = mime_type(type, type)
    else
      if actual = response[HEADER__CONTENT_TYPE]
        type, charset = actual.split(';')
        opts[:charset] ||= charset
      else
        type = CONTENT_TYPE__DEFAULT
      end
    end
    if charset = opts[:charset]
      type = '%s; charset=%s' % [type, charset]
    end
    response[HEADER__CONTENT_TYPE] = type
  end
  define_setup_method :content_type

  def charset charset
    content_type :charset => charset
  end
  define_setup_method :charset

  begin # authorization related methods

    # @example restricting all actions by using Basic authorization:
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

    def __e__authorize! auth_class, *auth_args, &auth_proc
      if auth_required = auth_class.new(proc {}, *auth_args, &auth_proc).call(env)
        halt auth_required
      end
    end
    private :__e__authorize!
  end

  begin # borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)

    # Specify response freshness policy for HTTP caches (Cache-Control header).
    # Any number of non-value directives (:public, :private, :no_cache,
    # :no_store, :must_revalidate, :proxy_revalidate) may be passed along with
    # a Hash of value directives (:max_age, :min_stale, :s_max_age).
    #
    #   cache_control :public, :must_revalidate, :max_age => 60
    #   => Cache-Control: public, must-revalidate, max-age=60
    #
    # See RFC 2616 / 14.9 for more on standard cache control directives:
    # http://tools.ietf.org/html/rfc2616#section-14.9.1
    def cache_control(*values)
      if values.last.kind_of?(Hash)
        hash = values.pop
        hash.reject! { |k,v| v == false }
        hash.reject! { |k,v| values << k if v == true }
      else
        hash = {}
      end

      values.map! { |value| value.to_s.tr('_','-') }
      hash.each do |key, value|
        key = key.to_s.tr('_', '-')
        value = value.to_i if key == "max-age"
        values << [key, value].join('=')
      end

      response['Cache-Control'] = values.join(', ') if values.any?
    end
    define_setup_method :cache_control

    # Set the Expires header and Cache-Control/max-age directive. Amount
    # can be an integer number of seconds in the future or a Time object
    # indicating when the response should be considered "stale". The remaining
    # "values" arguments are passed to the #cache_control helper:
    #
    #   expires 500, :public, :must_revalidate
    #   => Cache-Control: public, must-revalidate, max-age=60
    #   => Expires: Mon, 08 Jun 2009 08:50:17 GMT
    #
    def expires(amount, *values)
      values << {} unless values.last.kind_of?(Hash)

      if amount.is_a? Integer
        time    = Time.now + amount.to_i
        max_age = amount
      else
        time    = time_for amount
        max_age = time - Time.now
      end

      values.last.merge!(:max_age => max_age)
      cache_control(*values)

      response['Expires'] = time.httpdate
    end
    define_setup_method :expires

    # Set the last modified time of the resource (HTTP 'Last-Modified' header)
    # and halt if conditional GET matches. The +time+ argument is a Time,
    # DateTime, or other object that responds to +to_time+.
    #
    # When the current request includes an 'If-Modified-Since' header that is
    # equal or later than the time specified, execution is immediately halted
    # with a '304 Not Modified' response.
    def last_modified(time)
      return unless time
      time = time_for time
      response['Last-Modified'] = time.httpdate
      return if env['HTTP_IF_NONE_MATCH']

      if status == 200 and env['HTTP_IF_MODIFIED_SINCE']
        # compare based on seconds since epoch
        since = Time.httpdate(env['HTTP_IF_MODIFIED_SINCE']).to_i
        halt 304 if since >= time.to_i
      end

      if (success? or status == 412) and env['HTTP_IF_UNMODIFIED_SINCE']
        # compare based on seconds since epoch
        since = Time.httpdate(env['HTTP_IF_UNMODIFIED_SINCE']).to_i
        halt 412 if since < time.to_i
      end
    rescue ArgumentError
    end
    define_setup_method :last_modified

    # Set the response entity tag (HTTP 'ETag' header) and halt if conditional
    # GET matches. The +value+ argument is an identifier that uniquely
    # identifies the current version of the resource. The +kind+ argument
    # indicates whether the etag should be used as a :strong (default) or :weak
    # cache validator.
    #
    # When the current request includes an 'If-None-Match' header with a
    # matching etag, execution is immediately halted. If the request method is
    # GET or HEAD, a '304 Not Modified' response is sent.
    def etag(value, options = {})
      # Before touching this code, please double check RFC 2616 14.24 and 14.26.
      options      = {:kind => options} unless Hash === options
      kind         = options[:kind] || :strong
      new_resource = options.fetch(:new_resource) { request.post? }

      unless [:strong, :weak].include?(kind)
        raise ArgumentError, ":strong or :weak expected"
      end

      value = '"%s"' % value
      value = 'W/' + value if kind == :weak
      response['ETag'] = value

      if success? or status == 304
        if etag_matches? env['HTTP_IF_NONE_MATCH'], new_resource
          halt(request.safe? ? 304 : 412)
        end

        if env['HTTP_IF_MATCH']
          halt 412 unless etag_matches? env['HTTP_IF_MATCH'], new_resource
        end
      end
    end
    define_setup_method :etag

    # Generates a Time object from the given value.
    # Used by #expires and #last_modified.
    def time_for(value)
      if value.respond_to? :to_time
        value.to_time
      elsif value.is_a? Time
        value
      elsif value.respond_to? :new_offset
        # DateTime#to_time does the same on 1.9
        d = value.new_offset 0
        t = Time.utc d.year, d.mon, d.mday, d.hour, d.min, d.sec + d.sec_fraction
        t.getlocal
      elsif value.respond_to? :mday
        # Date#to_time does the same on 1.9
        Time.local(value.year, value.mon, value.mday)
      elsif value.is_a? Numeric
        Time.at value
      else
        Time.parse value.to_s
      end
    rescue ArgumentError => boom
      raise boom
    rescue Exception
      raise ArgumentError, "unable to convert #{value.inspect} to a Time object"
    end

    # Helper method checking if a ETag value list includes the current ETag.
    def etag_matches?(list, new_resource = request.post?)
      return !new_resource if list == '*'
      list.to_s.split(/\s*,\s*/).include? response['ETag']
    end
    private :etag_matches?
  end

end
