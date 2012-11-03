class E

  alias orig_params  params
  alias orig_cookies cookies

  # overriding Appetite's action invocation
  def action__invoke &proc
    if (restriction = self.class.restrictions?(action_with_format))
      auth_class, auth_args, auth_proc = restriction
      (auth_request = auth_class.new(proc {}, *auth_args, &auth_proc).call(env)) && halt(auth_request)
    end

    (cache_control = cache_control?) && cache_control!(*cache_control)
    (expires = expires?) && expires!(*expires)
    (content_type = format? ? mime_type(format) : content_type?) && content_type!(content_type)
    (charset = __e__.explicit_charset || charset?) && charset!(charset)

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

  # this proxy used to keep methods that rely on instance variables,
  # so the app instance namespace stays pristine,
  # and user defined variables wont clash with builtin variables.
  def __e__
    @__e__ ||= EspressoFrameworkInstanceVariables.new self
  end

  def response
    __e__.response ||= EspressoFrameworkResponse.new
  end

  def params
    __e__.params ||= indifferent_params(orig_params)
  end

  %w[ session flash cookies ].each do |m|
    define_method m do
      __e__.send m
    end
  end

  def user
    env['REMOTE_USER']
  end

  alias user? user

  # getting various setups accepted by browser.
  # `accept?` is for content type, `accept_charset?` for charset etc.
  # as per W3C specification.
  #
  # useful when your API need to know about browser's expectations.
  #
  # @example
  #    accept? 'json'
  #    accept? /xml/
  #    accept_charset? 'UTF-8'
  #    accept_charset? /iso/
  #    accept_encoding? 'gzip'
  #    accept_encoding? /zip/
  #    accept_language? 'en-gb'
  #    accept_language? /en\-(gb|us)/
  #    accept_ranges? 'bytes'
  #
  ['', '_charset', '_encoding', '_language', '_ranges'].each do |field|
    define_method 'accept' << field do
      __e__.send(__method__) ||
          __e__.send('%s=' % __method__, env['HTTP_ACCEPT' << field.upcase].to_s)
    end

    define_method 'accept%s?' % field do |value|
      self.send('accept' << field) =~ value.is_a?(Regexp) ? value : /#{value}/
    end
  end

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
  #        content_type! '.json'
  #        # ...
  #      end
  #    end
  #
  # @param [String] type
  # @param [String] charset
  def content_type! type = nil, charset = nil
    __e__.explicit_charset = charset if charset
    charset ||= (content_type = response['Content-Type']) &&
        content_type.scan(%r[.*;\s?charset=(.*)]i).flatten.first
    type && (Symbol === type) && (type = '.' << type.to_s)
    content_type = type ?
        (type =~ /\A\./ ? '' << mime_type(type) : type.split(';').first) : 'text/html'
    content_type << '; charset=' << charset if charset
    response['Content-Type'] = content_type
  end

  alias provide! content_type!
  alias provides! content_type!

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
  def charset! charset
    content_type! response['Content-Type'], charset
  end

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
    halt invoke *args
  end

  # same as `pass` except it returns the result instead of halting
  #
  # @param [Class] *args
  # @param [Proc] &proc
  def invoke *args, &proc

    if args.size == 0
      error 500, '`%s` expects an action(or an app and action) to be provided' % __method__
    end

    app = ::AppetiteUtils.is_app?(args.first) ? args.shift : self.class

    if args.size == 0
      error 500, 'Beside app, `%s` expects an action to be provided' % __method__
    end

    action = args.shift.to_sym
    route = app[action] || error(404, '%s app does not respond to %s action' % [app, action])
    rest_map = app.url_map[route]
    env.update 'SCRIPT_NAME' => route

    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env.update 'PATH_INFO' => path
      params.size > 0 &&
          env.update('QUERY_STRING' => build_nested_query(params))
    end
    app.new(nil, rest_map).call env, &proc
  end

  # same as `invoke` except it returns only body
  def fetch *args, &proc
    invoke(*args, &proc).last
  end

  # same as `halt` except it uses as body the proc defined by `error` at class level
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

    response[1]['Content-Disposition'] = opts[:attachment] ?
        'attachment; filename="%s"' % (opts[:filename] || ::File.basename(path)) :
        'inline'

    (content_type = opts[:content_type]) &&
        (response[1]['Content-Type'] = content_type)

    (last_modified = opts[:last_modified]) &&
        (response[1]['Last-Modified'] = last_modified)

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

  # The response object. See Rack::Response and Rack::ResponseHelpers for more info:
  # http://rack.rubyforge.org/doc/classes/Rack/Response.html
  # http://rack.rubyforge.org/doc/classes/Rack/Response/Helpers.html
  class EspressoFrameworkResponse < ::Rack::Response # class kindly borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)
    def body=(value)
      value = value.body while Rack::Response === value
      @body = String === value ? [value.to_str] : value
    end

    def each
      block_given? ? super : enum_for(:each)
    end

    def finish
      if status.to_i / 100 == 1
        headers.delete "Content-Length"
        headers.delete "Content-Type"
      elsif Array === body and not [204, 304].include?(status.to_i)
        headers["Content-Length"] = body.inject(0) { |l, p| l + Rack::Utils.bytesize(p) }.to_s
      end

      # Rack::Response#finish sometimes returns self as response body. We don't want that.
      status, headers, result = super
      result = body if result == self
      [status, headers, result]
    end
  end

  # Class of the response body in case you use #stream.
  #
  # Three things really matter: The front and back block (back being the
  # blog generating content, front the one sending it to the client) and
  # the scheduler, integrating with whatever concurrency feature the Rack
  # handler is using.
  #
  # Scheduler has to respond to defer and schedule.
  class EspressoFrameworkStream # class kindly borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)
    def self.schedule(*)
      yield
    end

    def self.defer(*)
      yield
    end

    def initialize(scheduler = self.class, keep_open = false, &back)
      @back, @scheduler, @keep_open = back.to_proc, scheduler, keep_open
      @callbacks, @closed = [], false
    end

    def close
      return if @closed
      @closed = true
      @scheduler.schedule { @callbacks.each { |c| c.call } }
    end

    def each(&front)
      @front = front
      @scheduler.defer do
        begin
          @back.call(self)
        rescue Exception => e
          @scheduler.schedule { raise e }
        end
        close unless @keep_open
      end
    end

    def <<(data)
      @scheduler.schedule { @front.call(data.to_s) }
      self
    end

    def callback(&block)
      @callbacks << block
    end

    alias errback callback
  end

  module EspressoFrameworkCoreHelpers # methods kindly borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)

    # Set or retrieve the response status code.
    def status(value=nil)
      response.status = value if value
      response.status
    end

    # Set or retrieve the response body. When a block is given,
    # evaluation is deferred until the body is read with #each.
    def body(value=nil, &block)
      if block_given?
        def block.each;
          yield(call)
        end

        response.body = block
      elsif value
        response.body = value
      else
        response.body
      end
    end

    # Allows to start sending data to the client even though later parts of
    # the response body have not yet been generated.
    #
    # The close parameter specifies whether Stream#close should be called
    # after the block has been executed. This is only relevant for evented
    # servers like Thin or Rainbows.
    def stream(keep_open = false)
      scheduler = env['async.callback'] ? EventMachine : EspressoFrameworkStream
      current = params.dup
      block = proc do |out|
        begin
          original, __e__.params = __e__.params, current
          yield(out)
        ensure
          __e__.params = original if original
        end
      end

      body EspressoFrameworkStream.new(scheduler, keep_open, &block)
    end

    # Specify response freshness policy for HTTP caches (Cache-Control header).
    # Any number of non-value directives (:public, :private, :no_cache,
    # :no_store, :must_revalidate, :proxy_revalidate) may be passed along with
    # a Hash of value directives (:max_age, :min_stale, :s_max_age).
    #
    #   cache_control! :public, :must_revalidate, :max_age => 60
    #   => Cache-Control: public, must-revalidate, max-age=60
    #
    # See RFC 2616 / 14.9 for more on standard cache control directives:
    # http://tools.ietf.org/html/rfc2616#section-14.9.1
    def cache_control!(*values)
      if values.last.kind_of?(Hash)
        hash = values.pop
        hash.reject! { |k, v| v == false }
        hash.reject! { |k, v| values << k if v == true }
      else
        hash = {}
      end

      values.map! { |value| value.to_s.tr('_', '-') }
      hash.each do |key, value|
        key = key.to_s.tr('_', '-')
        value = value.to_i if key == "max-age"
        values << [key, value].join('=')
      end

      response['Cache-Control'] = values.join(', ') if values.any?
    end

    # Set the Expires header and Cache-Control/max-age directive. Amount
    # can be an integer number of seconds in the future or a Time object
    # indicating when the response should be considered "stale". The remaining
    # "values" arguments are passed to the #cache_control! helper:
    #
    #   expires 500, :public, :must_revalidate
    #   => Cache-Control: public, must-revalidate, max-age=60
    #   => Expires: Mon, 08 Jun 2009 08:50:17 GMT
    #
    def expires!(amount, *values)
      values << {} unless values.last.kind_of?(Hash)

      if amount.is_a? Integer
        time = Time.now + amount.to_i
        max_age = amount
      else
        time = time_for amount
        max_age = time - Time.now
      end

      values.last.merge!(:max_age => max_age)
      cache_control!(*values)

      response['Expires'] = time.httpdate
    end

    # Set the last modified time of the resource (HTTP 'Last-Modified' header)
    # and halt if conditional GET matches. The +time+ argument is a Time,
    # DateTime, or other object that responds to +to_time+.
    #
    # When the current request includes an 'If-Modified-Since' header that is
    # equal or later than the time specified, execution is immediately halted
    # with a '304 Not Modified' response.
    def last_modified!(time)
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

    # Set the response entity tag (HTTP 'ETag' header) and halt if conditional
    # GET matches. The +value+ argument is an identifier that uniquely
    # identifies the current version of the resource. The +kind+ argument
    # indicates whether the etag should be used as a :strong (default) or :weak cache validator.
    #
    # When the current request includes an 'If-None-Match' header with a
    # matching etag, execution is immediately halted. If the request method is
    # GET or HEAD, a '304 Not Modified' response is sent.
    def etag!(value, options = {})
      # Before touching this code, please double check RFC 2616 14.24 and 14.26.
      options = {:kind => options} unless Hash === options
      kind = options[:kind] || :strong
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
  include EspressoFrameworkCoreHelpers

  class EspressoFrameworkInstanceVariables

    include ::Rack::Utils

    attr_accessor :response, :params,
                  :accept, :accept_charset, :accept_encoding, :accept_language, :accept_ranges,
                  :explicit_charset

    def initialize ctrl
      @ctrl = ctrl
    end

    # a simple wrapper around Rack::Session
    def session
      @session_proxy ||= Class.new do
        attr_reader :session

        def initialize session = {}
          @session = session
        end

        def [] key
          session[key]
        end

        def []= key, val
          return if readonly?
          session[key] = val
        end

        def delete key
          return if readonly?
          session.delete key
        end

        # makes sessions readonly
        #
        # @example prohibit writing for all actions
        #    before do
        #      session.readonly!
        #    end
        #
        # @example prohibit writing only for :render and :display actions
        #    before :render, :display do
        #      session.readonly!
        #    end
        def readonly!
          @readonly = true
        end

        def readonly?
          @readonly
        end

        def method_missing *args
          session.send *args
        end

      end.new @ctrl.env['rack.session']
    end

    # @example
    #    flash[:alert] = 'Item Deleted'
    #    p flash[:alert] #=> "Item Deleted"
    #    p flash[:alert] #=> nil
    #
    # @note if sessions are confined, flash will not work,
    #       so do not confine sessions for all actions,
    #       confine them only for actions really need this.
    def flash
      @flash_proxy ||= Class.new do
        attr_reader :session

        def initialize session = {}
          @session = session
        end

        def []= key, val
          session[key(key)] = val
        end

        def [] key
          return unless val = session[key = key(key)]
          session.delete key
          val
        end

        def key key
          '__e__session__flash__-' << key.to_s
        end
      end.new @ctrl.env['rack.session']
    end

    # shorthand for `response.set_cookie` and `response.delete_cookie`.
    # also it allow to make cookies readonly.
    def cookies
      @cookies_proxy ||= Class.new do
        attr_reader :controller, :response

        def initialize controller
          @controller, @response = controller, controller.response
        end

        # set cookie header
        #
        # @param [String, Symbol] key
        # @param [String, Hash] val
        # @return [Boolean]
        def []= key, val
          return if readonly?
          response.set_cookie key, val
        end

        # get cookie by key
        def [] key
          controller.orig_cookies[key]
        end

        # instruct browser to delete a cookie
        #
        # @param [String, Symbol] key
        # @param [Hash] opts
        # @return [Boolean]
        def delete key, opts ={}
          return if readonly?
          response.delete_cookie key, opts
        end

        # prohibit further cookies writing
        #
        # @example prohibit writing for all actions
        #    before do
        #      cookies.readonly!
        #    end
        #
        # @example prohibit writing only for :render and :display actions
        #    before :render, :display do
        #      cookies.readonly!
        #    end
        def readonly!
          @readonly = true
        end

        def readonly?
          @readonly
        end

        def method_missing *args
          controller.orig_cookies.send *args
        end
      end.new @ctrl
    end

  end

end
