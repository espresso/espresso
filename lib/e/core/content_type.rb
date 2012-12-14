class << E

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
end

class E
  # set Content-Type header
  #
  # Content-Type will be guessed by passing given type to `mime_type`
  #
  # if second arg given, it will be added as charset
  #
  # you do not need to manually set Content-Type inside each action.
  # this can be done automatically by using `content_type` at class level
  #
  # @example set Content-Type at class level for all actions
  #    class App < E
  #      # ...
  #      content_type '.json'
  #    end
  #
  # @example set Content-Type at class level for :news and :feed actions
  #    class App < E
  #      # ...
  #      setup :news, :feed do
  #        content_type '.json'
  #      end
  #    end
  #
  # @example set Content-Type at instance level
  #    class App < E
  #      # ...
  #      def news
  #        content_type '.json'
  #        # ...
  #      end
  #    end
  #
  # @param [String] type
  # @param [String] charset
  def content_type type = nil, charset = nil
    @__e__explicit_charset = charset if charset
    charset ||= (content_type = response[HEADER__CONTENT_TYPE]) &&
      content_type.scan(%r[.*;\s?charset=(.*)]i).flatten.first
    type = '.' << type.to_s if type && type.is_a?(Symbol)
    content_type = String.new(type ?
      (type =~ /\A\./ ? mime_type(type) : type.split(';').first) :
      CONTENT_TYPE__DEFAULT)
    content_type << '; charset=' << charset if charset
    response[HEADER__CONTENT_TYPE] = content_type
  end
  alias content_type! content_type
  alias provide! content_type
  alias provides! content_type
  alias provide content_type
  alias provides content_type

  def content_type? action = action_with_format
    self.class.content_type?(action)
  end

  # update Content-Type header by add/update charset.
  #
  # @note please make sure that returned body is of same charset,
  #       cause Appetite will only set header and not change the charset of body itself!
  #
  # @note you do not need to set charset inside each action.
  #       this can be done automatically by using `charset` at class level.
  #
  # @example set charset at class level for all actions
  #    class App < E
  #      # ...
  #      charset 'UTF-8'
  #    end
  #
  # @example set charset at class level for :feed and :recent actions
  #    class App < E
  #      # ...
  #      setup :feed, :recent do
  #        charset 'UTF-8'
  #      end
  #    end
  #
  # @example set charset at instance level
  #    class App < E
  #      # ...
  #      def news
  #        # ...
  #        charset! 'UTF-8'
  #        # body of same charset as `charset!`
  #      end
  #    end
  #
  # @note make sure you have defined Content-Type(at class or instance level)
  #       header before using `charset`
  #
  # @param [String] charset
  def charset charset
    content_type response[HEADER__CONTENT_TYPE], charset
  end
  alias charset! charset

  def charset? action = action_with_format
    self.class.charset?(action)
  end
end
