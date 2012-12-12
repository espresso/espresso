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