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
      invoke_before_filters

      super
      invoke_after_filters
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
end
