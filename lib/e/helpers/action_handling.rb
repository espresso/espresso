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
end