class << E
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
end

class E
  
  def cache_control? action = action_with_format
    self.class.cache_control? action
  end

  def expires? action = action_with_format
    self.class.expires? action
  end

  # methods below kindly borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)

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
  alias cache_control! cache_control

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
  alias expires! expires

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
  alias last_modified! last_modified

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
  alias etag! etag

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

  private

  # Helper method checking if a ETag value list includes the current ETag.
  def etag_matches?(list, new_resource = request.post?)
    return !new_resource if list == '*'
    list.to_s.split(/\s*,\s*/).include? response['ETag']
  end
end
