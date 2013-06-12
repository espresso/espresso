class ERewriter
  include Rack::Utils
  include EConstants
  include EUtils

  attr_reader :env, :request

  def initialize *matches, &proc
    @matches, @proc = matches, proc
  end

  def call env
    @env, @request = env, ERequest.new(env)
    @status, @headers, @body =
      STATUS__NOT_FOUND, {"Content-Type" => "text/plain"}, []

    catch :__e__rewriter__halt_symbol__ do
      self.instance_exec *@matches, &@proc
    end
    [@status, @headers, @body]
  end

  def redirect location
    @status = STATUS__REDIRECT
    @headers[HEADER__LOCATION] = location
    throw :__e__rewriter__halt_symbol__
  end

  def permanent_redirect location
    @status = STATUS__PERMANENT_REDIRECT
    @headers[HEADER__LOCATION] = location
    throw :__e__rewriter__halt_symbol__
  end

  def pass *args
    if args.empty?
      @status = STATUS__PASS
      throw :__e__rewriter__halt_symbol__
    end

    ctrl = (args.size > 0 && is_app?(args.first) && args.shift) ||
      raise(ArgumentError, "Controller missing. Please provide it as first argument when calling `pass' inside a rewrite rule block.")

    action = args.shift
    route = ctrl[action] ||
      raise(ArgumentError, '%s controller does not respond to %s action' % [ctrl, action.inspect])

    env[ENV__SCRIPT_NAME] = route
    env[ENV__REQUEST_URI] = env[ENV__PATH_INFO] = ''

    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env[ENV__PATH_INFO] = env[ENV__REQUEST_URI] = path
      params.size > 0 &&
        env.update(ENV__QUERY_STRING => build_nested_query(params))
    end
    @status, @headers, @body = ctrl.new(action).call(env)
    throw :__e__rewriter__halt_symbol__
  end

  def halt *args
    args.each do |a|
      case a
        when Array
          @status, @headers, @body = a
        when Fixnum
          @status = a
        when Hash
          @headers.update a
        else
          @body = [a]
      end
    end
    @status ||= STATUS__OK
    throw :__e__rewriter__halt_symbol__
  end
end
