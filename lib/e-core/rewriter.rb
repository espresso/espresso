class EspressoFrameworkRewriter
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
  include Rack::Utils

  attr_reader :env, :request

  class << self
    attr_accessor :rules
  end

  def initialize app
    @app = app
  end

  def call env
    @env, @request = env, Rack::Request.new(env)
    matched? ? [@status, @headers, @body] : @app.call(env)
  end

  def matched?
    path = request.path
    @status, @headers, @body = nil, {}, []

    catch :__e__rewriter__halt_symbol__ do
      self.class.rules.each do |rule|
        next unless (matches = path.match(rule.first))
        self.instance_exec *matches.captures, &rule.last
        break
      end
    end
    @status
  end

  def redirect location
    @status = STATUS__REDIRECT
    @headers['Location'] = location
  end

  def permanent_redirect location
    redirect location
    @status = STATUS__PERMANENT_REDIRECT
  end

  def pass *args
    ctrl = (args.size > 0 && is_app?(args.first) && args.shift) ||
      raise(ArgumentError, "Controller missing. Please provide it as first argument when calling `pass' inside a rewrite rule block.")

    action = args.shift
    route = ctrl[action] ||
      raise(ArgumentError, '%s controller does not respond to %s action' % [ctrl, action.inspect])
    rest_map = ctrl.url_map[route]

    env.update 'SCRIPT_NAME' => route, 'REQUEST_URI' => '', 'PATH_INFO' => ''
    if args.size > 0
      path, params = '/', {}
      args.each { |a| a.is_a?(Hash) ? params.update(a) : path << a.to_s << '/' }
      env.update('PATH_INFO' => path)
      params.size > 0 &&
        env.update('QUERY_STRING' => build_nested_query(params))
    end
    @status, @headers, @body = ctrl.allocate.call(env)
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
