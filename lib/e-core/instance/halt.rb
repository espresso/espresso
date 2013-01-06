class E

  # stop executing any code and send response to browser.
  #
  # accepts an arbitrary number of arguments.
  # if arg is an Integer, it will be used as status code.
  # if arg is a Hash, it is treated as headers.
  # if it is an array, it is treated as Rack response and are sent immediately, ignoring other args.
  # any other args are treated as body.
  #
  # @example returning "Well Done" body with 200 status code
  #    halt 'Well Done'
  #
  # @example halting quietly, with empty body and 200 status code
  #    halt
  #
  # @example returning error with 500 code:
  #    halt 500, 'Sorry, some fatal error occurred'
  #
  # @example custom content type
  #    halt File.read('/path/to/theme.css'), 'Content-Type' => mime_type('.css')
  #
  # @example sending custom Rack response
  #    halt [200, {'Content-Disposition' => "attachment; filename=some-file"}, some_IO_instance]
  #
  # @param [Array] *args
  def halt *args
    args.each do |a|
      case a
        when Fixnum
          response.status = a
        when Array
          status, headers, body = a
          response.status = status
          response.headers.update headers
          response.body = body
        when Hash
          response.headers.update a
        else
          response.body = [a.to_s]
      end
    end
    response.body ||= []
    throw :__e__catch__response__, response
  end

  # same as `halt(error_code)` except it carrying previous defined error handlers.
  #
  # @example
  #    class App < E
  #
  #      # defining the proc to be executed on 404 errors
  #      error 404 do |message|
  #        render_layout('layouts/404') { message }
  #      end
  #
  #      def index id, status
  #        item = Model.fisrt(:id => id, :status => status)
  #        unless item
  #          # interrupt execution and send 404 error to browser.
  #          fail 404, 'Can not find item by given ID and Status'
  #        end
  #        # code here will be executed only if item found
  #      end
  #    end
  #
  def fail error_code = STATUS__SERVER_ERROR, body = nil
    if handler = error_handler_defined?(error_code)
      meth, arity = handler
      body = arity > 0 ? self.send(meth, body) : [self.send(meth), body].join
    end
    halt error_code.to_i, body
  end
  alias fail!  fail
  alias quit   fail
  alias quit!  fail
  alias error  fail
  alias error! fail

  def error_handler_defined? error_code
    self.class.error_handler(error_code) || self.class.error_handler(:*)
  end

  # simply pass control to another action or even controller.
  #
  # by default, it will pass control to an action on current controller.
  # however, if first argument is a controller, control will be passed to given it.
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
    halt invoke(*args), &proc
  end

  # same as `pass` except it returns the result instead of halting
  #
  # @note it will use current REQUEST_METHOD to issue a request.
  #       to use another request method use #[pass|invoke|fetch]_via_[verb]
  #       ex: #pass_via_get, #fetch_via_post etc
  #
  # @note to update passed env, use a block.
  #       the block will receive the env and therefore you can update it as needed.
  #
  # @param [Class] *args
  def invoke *args

    if args.empty?
      return [500, {}, '`%s` expects an action(or a Controller and some action) to be provided' % __method__]
    end

    controller = EspressoFrameworkUtils.is_app?(args.first) ? args.shift : self.class

    if args.empty?
      return [500, {}, 'Beside Controller, `%s` expects some action to be provided' % __method__]
    end

    action = args.shift.to_sym
    unless route = controller[action]
      return [404, {}, '%s does not respond to %s action' % [controller, action]]
    end

    env = Hash[env()] # faster than #dup
    if block_given?
      yield env
    end
    env[ENV__SCRIPT_NAME] = route
    env[ENV__REQUEST_URI] = env[ENV__PATH_INFO] = ''
    env[ENV__ESPRESSO_PATH_INFO] = nil

    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env[ENV__PATH_INFO] = env[ENV__REQUEST_URI] = path
      
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

  # defining methods that will allow to issue requests via custom request method.
  # eg. #pass_via_get, #invoke_via_post, # fetch_via_post etc.
  HTTP__REQUEST_METHODS.each do |rm|
    %w[invoke pass fetch].each do |meth|
      define_method '%s_via_%s' % [meth, rm.downcase] do |*args|
        self.send(meth, *args) { |env| env.update ENV__REQUEST_METHOD => rm }
      end
    end
  end

end
