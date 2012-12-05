class E

  # overriding Appetite's action invocation
  # by adding authorization, hooks, cache control etc.
  def action__invoke &proc
    if (restriction = self.class.restrictions?(action_with_format))
      auth_class, auth_args, auth_proc = restriction
      (auth_request = auth_class.new(proc {}, *auth_args, &auth_proc).call(env)) && halt(auth_request)
    end

    (cache_control = cache_control?) && cache_control!(*cache_control)
    (expires = expires?) && expires!(*expires)
    (content_type = format? ? mime_type(format) : content_type?) && content_type(content_type)
    (charset = @__e__explicit_charset || charset?) && charset(charset)

    begin
      (self.class.hooks?(:a, action_with_format)||[]).each { |m| self.send m }
      super
      (self.class.hooks?(:z, action_with_format)||[]).each { |m| self.send m }
    rescue => e
      # if a handler defined at class level, use it
      if handler = self.class.error?(500, action)
        body = handler.last > 0 ? self.send(handler.first, e) : self.send(handler.first)
        halt 500, body
      else
        # otherwise raise rescued exception
        raise e
      end
    end

  end

  def user
    env[ENV__REMOTE_USER]
  end
  alias user? user

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

  def cache_control? action = action_with_format
    self.class.cache_control? action
  end

  def expires? action = action_with_format
    self.class.expires? action
  end

  # simply pass control to another action.
  #
  # by default, it will pass control to an action on current app.
  # however, if first argument is a app, control will be passed to given app.
  #
  # by default, it will pass with given path parameters, i.e. PATH_INFO
  # if you pass some arguments beside action, they will be passed to destination action.
  #
  # @example pass control to #control_panel if user authorized
  #    def index
  #      pass :control_panel if user?
  #    end
  #
  # @example passing with modified arguments
  #    def index id, action
  #      pass action, id
  #    end
  #
  # @example passing with modified arguments and custom HTTP params
  #    def index id, action
  #      pass action, id, :foo => :bar
  #    end
  #
  # @example passing control to inner app
  #    def index id, action
  #      pass Articles, :news, action, id
  #    end
  #
  # @param [Class] *args
  # @param [Proc] &proc
  def pass *args
    halt invoke(*args)
  end

  # same as `pass` except it returns the result instead of halting
  #
  # @param [Class] *args
  # @param [Proc] &proc
  def invoke *args, &proc

    if args.size == 0
      return [500, {}, '`%s` expects an action(or a Controller and some action) to be provided' % __method__]
    end

    app = ::AppetiteUtils.is_app?(args.first) ? args.shift : self.class

    if args.size == 0
      return [500, {}, 'Beside Controller, `%s` expects some action to be provided' % __method__]
    end

    action = args.shift.to_sym
    unless route = app[action]
      return [404, {}, '%s does not respond to %s action' % [app, action]]
    end
    env.update ENV__SCRIPT_NAME => route

    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env.update ENV__PATH_INFO => path
      params.size > 0 &&
        env.update(ENV__QUERY_STRING => build_nested_query(params))
    end
    app.new.call env, &proc
  end

  # same as `invoke` except it returns only body
  def fetch *args, &proc
    body = invoke(*args, &proc).last
    body = body.body if body.respond_to?(:body)
    body.is_a?(Array) ? body.inject('') {|b,c| b << c.to_s} : body
  end

  # same as `halt` except it uses for body the proc defined by `error` at class level
  #
  # @example
  #    class App < E
  #
  #      # defining the proc to be executed on 404 errors
  #      error 404 do |message|
  #        render_view('layouts/404'){ message }
  #      end
  #
  #      get :index do |id, status|
  #        item = Model.fisrt id: id, status: status
  #        unless item
  #          # interrupt execution and send 404 error to browser.
  #          error 404, 'Can not find item by given ID and Status'
  #        end
  #        # if no item found, code here will not be executed
  #      end
  #    end
  def error status, body = nil
    (handler = self.class.error?(status)) &&
      (body = handler.last > 0 ? self.send(handler.first, body) : self.send(handler.first))
    halt status.to_i, body
  end

  # Serving static files.
  # Note that this blocks app while file readed/transmitted(on WEBrick and Thin, as minimum).
  # To avoid app locking, setup your Nginx/Lighttpd server to set proper X-Sendfile header
  # and use Rack::Sendfile middleware in your app.
  #
  # @param [String] path full path to file
  # @param [Hash] opts
  # @option opts [String] filename the name of file displayed in browser's save dialog
  # @option opts [String] content_type custom content_type
  # @option opts [String] last_modified
  # @option opts [String] cache_control
  # @option opts [Boolean] attachment if set to true, browser will prompt user to save file
  def send_file path, opts = {}

    file = ::Rack::File.new nil
    file.path = path
    (cache_control = opts[:cache_control]) && (file.cache_control = cache_control)
    response = file.serving env

    response[1][HEADER__CONTENT_DISPOSITION] = opts[:attachment] ?
        'attachment; filename="%s"' % (opts[:filename] || ::File.basename(path)) :
        'inline'

    (content_type = opts[:content_type]) &&
      (response[1][HEADER__CONTENT_TYPE] = content_type)

    (last_modified = opts[:last_modified]) &&
      (response[1][HEADER__LAST_MODIFIED] = last_modified)

    halt response
  end

  # serve static files at dir path
  def send_files dir
    halt ::Rack::Directory.new(dir).call(env)
  end

  # same as `send_file` except it instruct browser to display save dialog
  def attachment path, opts = {}
    halt send_file path, opts.merge(:attachment => true)
  end

  def app
    self.class.app
  end

  def app_root
    app.root
  end

  def escape_html *args
    ::CGI.escapeHTML *args
  end

  def unescape_html *args
    ::CGI.unescapeHTML *args
  end

  def escape_element *args
    ::CGI.escapeElement *args
  end

  def unescape_element *args
    ::CGI.unescapeElement *args
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

  # Sugar for redirect (example:  redirect back)
  def back
    request.referer
  end

  # whether or not the status is set to 1xx
  def informational?
    status.between? 100, 199
  end

  # whether or not the status is set to 2xx
  def success?
    status.between? 200, 299
  end

  # whether or not the status is set to 3xx
  def redirect?
    status.between? 300, 399
  end

  # whether or not the status is set to 4xx
  def client_error?
    status.between? 400, 499
  end

  # whether or not the status is set to 5xx
  def server_error?
    status.between? 500, 599
  end

  # whether or not the status is set to 404
  def not_found?
    status == 404
  end

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
