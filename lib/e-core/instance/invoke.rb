class E

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
      return [EConstants::STATUS__BAD_REQUEST, {}, [body]]
    end

    controller = EUtils.is_app?(args.first) ? args.shift : self.class

    if args.empty?
      body = 'Beside Controller, `invoke` expects some action to be provided'
      return [EConstants::STATUS__BAD_REQUEST, {}, [body]]
    end

    action = args.shift.to_sym
    unless route = controller[action]
      body = '%s does not respond to %s action' % [controller, action]
      return [EConstants::STATUS__NOT_FOUND, {}, [body]]
    end

    env = Hash[env()] # faster than #dup
    yield(env) if block_given?
    env[EConstants::ENV__SCRIPT_NAME]  = route
    env[EConstants::ENV__PATH_INFO]    = ''
    env[EConstants::ENV__QUERY_STRING] = ''
    env[EConstants::ENV__REQUEST_URI]  = ''

    if args.size > 0
      path, params = [''], {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a }
      env[EConstants::ENV__PATH_INFO] = env[EConstants::ENV__REQUEST_URI] = path.join('/')
      
      if params.any?
        env.update(EConstants::ENV__QUERY_STRING => build_nested_query(params))
        env['rack.input'] = StringIO.new
      end
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
    define_method 'xhr_%s' % meth do |*args, &proc|
      self.send(meth, *args) do |env|
        proc.call(env) if proc
        env.update EConstants::ENV__HTTP_X_REQUESTED_WITH => EConstants::ENV__XML_HTTP_REQUEST
      end
    end

    EConstants::HTTP__REQUEST_METHODS.each do |rm|
      # defining methods that will allow to issue requests via custom request method.
      # ex: #pass_via_get, #invoke_via_post, #fetch_via_post etc.
      define_method '%s_via_%s' % [meth, rm.downcase] do |*args, &proc|
        self.send(meth, *args) do |env|
          proc.call(env) if proc
          env.update EConstants::ENV__REQUEST_METHOD => rm
        end
      end

      # defining methods like
      # #xhr_pass_via_post, #xhr_fetch_via_get etc
      define_method 'xhr_%s_via_%s' % [meth, rm.downcase] do |*args, &proc|
        self.send(meth, *args) do |env|
          proc.call(env) if proc
          env.update({
            EConstants::ENV__REQUEST_METHOD => rm,
            EConstants::ENV__HTTP_X_REQUESTED_WITH => EConstants::ENV__XML_HTTP_REQUEST
          })
        end
      end
    end
  end

end
