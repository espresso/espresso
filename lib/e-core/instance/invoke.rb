class E

  # simply pass control and data to another action or controller.
  #
  # by default, it will pass control to an action on current controller.
  # however, if first argument is a controller, control will be passed to it.
  #
  # @example pass control to #control_panel if user authorized
  #    def index
  #      pass :control_panel if user?
  #    end
  #
  # @example passing with modified arguments
  #    def index id
  #      pass :update, id
  #    end
  #
  # @example passing with modified arguments and custom HTTP params
  #    def index id, column
  #      pass :update, column, :value => id
  #    end
  #
  # @example passing control to inner controller
  #    def index id
  #      pass Articles, :render_item, id
  #    end
  #
  # @param [Array] *args
  #
  def pass *args, &proc
    args << params() unless args.any? {|a| a.is_a?(Hash)}
    halt invoke(*args, &proc)
  end

  # invoke some action via HTTP.
  # to invoke an action on inner controller,
  # pass controller as first argument and the action as second.
  # 
  # @note unlike `pass`, `invoke` will not pass any data!
  # 
  # @note it will use current REQUEST_METHOD to issue a request.
  #       to use another request method use #[pass|invoke|fetch]_via_[verb]
  #       ex: #pass_via_get, #fetch_via_post etc
  #
  # @note to update passed env, use a block.
  #       the block will receive the env as first argument
  #       and therefore you can update it as needed.
  #
  # @param [Class] *args
  def invoke *args

    if args.empty?
      body = '`invoke` expects some action(or a Controller and some action) to be provided'
      return [STATUS__BAD_REQUEST, {}, [body]]
    end

    controller = EspressoUtils.is_app?(args.first) ? args.shift : self.class

    if args.empty?
      body = 'Beside Controller, `invoke` expects some action to be provided'
      return [STATUS__BAD_REQUEST, {}, [body]]
    end

    action = args.shift.to_sym
    unless route = controller[action]
      body = '%s does not respond to %s action' % [controller, action]
      return [STATUS__NOT_FOUND, {}, [body]]
    end

    env = Hash[env()] # faster than #dup
    if block_given?
      yield env
    end
    env[ENV__SCRIPT_NAME]  = route
    env[ENV__PATH_INFO]    = ''
    env[ENV__QUERY_STRING] = ''
    env[ENV__REQUEST_URI]  = ''
    env[ENV__ESPRESSO_PATH_INFO] = nil

    if args.size > 0
      path, params = [''], {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a }
      env[ENV__PATH_INFO] = env[ENV__REQUEST_URI] = path.join('/')
      
      params.any? &&
        env.update(ENV__QUERY_STRING => build_nested_query(params))
    end
    controller.new(action).call(env)
  end

  # same as `invoke` except it returns only body
  def fetch *args, &proc
    body = invoke(*args, &proc).last
    body = body.body if body.respond_to?(:body)
    body.respond_to?(:join) ? body.join : body
  end

  %w[invoke pass fetch].each do |meth|
    # defining methods that will allow to issue requests via XHR, aka. Ajax.
    # ex: #xhr_pass, #xhr_fetch, #xhr_invoke
    define_method 'xhr_%s' % meth do |*args|
      self.send(meth, *args) { |env| env.update ENV__HTTP_X_REQUESTED_WITH => 'XMLHttpRequest' }
    end

    HTTP__REQUEST_METHODS.each do |rm|
      # defining methods that will allow to issue requests via custom request method.
      # ex: #pass_via_get, #invoke_via_post, #fetch_via_post etc.
      define_method '%s_via_%s' % [meth, rm.downcase] do |*args|
        self.send(meth, *args) { |env| env.update ENV__REQUEST_METHOD => rm }
      end

      # defining methods like
      # #xhr_pass_via_post, #xhr_fetch_via_get etc
      define_method 'xhr_%s_via_%s' % [meth, rm.downcase] do |*args|
        self.send(meth, *args) do |env|
          env.update ENV__REQUEST_METHOD => rm, ENV__HTTP_X_REQUESTED_WITH => 'XMLHttpRequest'
        end
      end

    end
  end

end
