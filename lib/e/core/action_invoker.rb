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
  
end
