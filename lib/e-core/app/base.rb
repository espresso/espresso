class EspressoApp

  def self.call env
    new(:automount).call(env)
  end

  # creates new Espresso app.
  # 
  # @param automount  if set to any positive value(except Class, Module or Regexp),
  #                   all found controllers will be mounted,
  #                   if set to a Class, Module or Regexp,
  #                   only controllers under given namespace will be mounted.
  # @param [Proc] proc if block given, it will be executed inside newly created app
  #
  def initialize automount = false, &proc
    @routes, @controllers = {}, {}
    @automount = automount
    proc && self.instance_exec(&proc)
    use ExtendedRack
  end

  # mount given/discovered controllers into current app.
  # any number of arguments accepted.
  # String arguments are treated as roots/canonicals.
  # any other arguments are used to discover controllers.
  # controllers can be passed directly
  # or as a Module that contain controllers
  # or as a Regexp matching controller's name.
  # 
  # proc given here will be executed inside given/discovered controllers.
  #
  def mount *args, &setup
    controllers, roots = [], []
    args.flatten.each do |a|
      if a.is_a?(String)
        roots << rootify_url(a)
      elsif is_app?(a)
        controllers << a
      else
        controllers.concat extract_controllers(a)
      end
    end
    controllers.each do |c|
      @controllers[c] = [roots, setup]
    end
    self
  end

  # auto-mount auto-discovered controllers.
  # call this only after all controllers defined and app ready to start!
  # leaving it in public zone for better control over mounting.
  def automount!
    controllers = [Class, Module, Regexp].include?(@automount.class) ?
      extract_controllers(@automount) :
      discover_controllers
    mount controllers.select {|c| c.accept_automount?}
  end

  # proc given here will be executed inside all controllers.
  # used to setup multiple controllers at once.
  def global_setup &proc
    @global_setup = proc
    self
  end
  alias setup_controllers global_setup
  alias controllers_setup global_setup
  alias setup global_setup

  # displays URLs the app will respond to,
  # with controller and action that serving each URL.
  def url_map opts = {}
    to_app!
    map = {}
    sorted_routes.each do |r|
      @routes[r].each_pair { |rm, as| (map[r] ||= {})[rm] = as.dup }
    end

    def map.to_s
      out = []
      self.each_pair do |route, request_methods|
        next if route.source.size == 0
        out << "%s\n" % route.source
        request_methods.each_pair do |request_method, route_setup|
          out << "  %s%s" % [request_method, ' ' * (10 - request_method.to_s.size)]
          out << "%s#%s\n" % [route_setup[:controller], route_setup[:action]]
        end
        out << "\n"
      end
      out.join
    end
    map
  end
  alias urlmap url_map

  # by default, Espresso will use WEBrick server.
  # pass :server option and any option accepted by selected(or default) server:
  #
  # @example use Thin server on its default port
  #   app.run :server => :Thin
  # @example use EventedMongrel server with custom options
  #   app.run :server => :EventedMongrel, :port => 9090, :num_processors => 1000
  #
  # @param [Hash] opts
  # @option opts [Symbol]  :server (:WEBrick) web server
  # @option opts [Integer] :port   (5252)
  # @option opts [String]  :host   (0.0.0.0)
  #
  def run opts = {}
    server = opts.delete(:server)
    (server && Rack::Handler.const_defined?(server)) || (server = HTTP__DEFAULT_SERVER)

    port = opts.delete(:port)
    opts[:Port] ||= port || HTTP__DEFAULT_PORT

    host = opts.delete(:host) || opts.delete(:bind)
    opts[:Host] = host if host

    Rack::Handler.const_get(server).run app, opts
  end

  def call env
    app.call env
  end

  def app
    @app ||= begin
      mount_controllers!
      middleware.reverse.inject(lambda {|env| call!(env)}) {|a,e| e[a]}
    end
  end

  def to_app
    app
    self
  end
  alias to_app! to_app
  alias boot!   to_app

  private
  def call! env
    path = env[ENV__PATH_INFO]
    script_name = env[ENV__SCRIPT_NAME]
    sorted_routes.each do |route|
      if matches = route.match(path)

        if route_setup = @routes[route][env[ENV__REQUEST_METHOD]] || @routes[route][:*]

          if route_setup[:rewriter]
            app = EspressoRewriter.new(*matches.captures, &route_setup[:rewriter])
            return app.call(env)
          elsif route_setup[:app]
            env[ENV__PATH_INFO] = matches[1].to_s
            return route_setup[:app].call(env)
          else
            path_info = matches[1].to_s

            env[ENV__SCRIPT_NAME] = (route_setup[:path]).freeze
            env[ENV__PATH_INFO]   = (path_ok?(path_info) ? path_info : '/' << path_info).freeze

            epi, format = nil
            (fr = route_setup[:format_regexp]) && (epi, format = path_info.split(fr))
            env[ENV__ESPRESSO_PATH_INFO] = epi
            env[ENV__ESPRESSO_FORMAT]    = format

            controller_instance = route_setup[:controller].new
            controller_instance.action_setup = route_setup
            app = Rack::Builder.new
            app.run controller_instance
            route_setup[:controller].middleware.each {|w,a,p| app.use w, *a, &p}
            return app.call(env)
          end
        else
          return [
            STATUS__NOT_IMPLEMENTED,
            {"Content-Type" => "text/plain"},
            ["Resource found but it can be accessed only through %s" % @routes[route].keys.join(", ")]
          ]
        end
      end
    end
    [
      STATUS__NOT_FOUND,
      {"Content-Type" => "text/plain", "X-Cascade" => "pass"},
      ["Not Found: #{env[ENV__PATH_INFO]}"]
    ]
  ensure
    env[ENV__PATH_INFO] = path
    env[ENV__SCRIPT_NAME] = script_name
  end

  def sorted_routes
    @sorted_routes ||= @routes.keys.sort {|a,b| b.source.size <=> a.source.size}
  end

  # checking whether path is empty or starts with a slash
  def path_ok? path
    # comparing fixnums are much faster than comparing strings
    path.hash == (@empty_string_hash ||= '' .hash) || # faster than path.empty?
      path[0].hash == (@slash_hash   ||= '/'.hash)    # faster than path =~ /^\//
  end

  def mount_controllers!
    automount! if @automount
    @mounted_controllers = []
    @controllers.each_pair {|c,(roots,setup)| mount_controller c, *roots, &setup}
  end

  def mount_controller controller, *roots, &setup
    return if @mounted_controllers.include?(controller)

    root = roots.shift
    if root || base_url.size > 0
      controller.remap!(base_url + root.to_s, *roots)
    end

    @global_setup && controller.global_setup!(&@global_setup)
    setup && controller.external_setup!(&setup)

    controller.mount! self

    @routes.update controller.routes
    controller.rewrite_rules.each {|(rule,proc)| rewrite_rule(rule, &proc)}

    @mounted_controllers << controller
  end

  def discover_controllers namespace = nil
    controllers = ObjectSpace.each_object(Class).
      select { |c| is_app?(c) }.reject { |c| [E].include? c }
    namespace.is_a?(Regexp) ?
      controllers.select { |c| c.name =~ namespace } :
      controllers
  end
  alias discovered_controllers discover_controllers

  def extract_controllers namespace
    if [Class, Module].include?(namespace.class)
      return discover_controllers.select {|c| c.name =~ /\A#{namespace}/}
    end
    discover_controllers namespace
  end

  # Some Rack handlers (Thin, Rainbows!) implement an extended body object protocol, however,
  # some middleware (namely Rack::Lint) will break it by not mirroring the methods in question.
  # This middleware will detect an extended body object and will make sure it reaches the
  # handler directly. We do this here, so our middleware and middleware set up by the app will
  # still be able to run.
  class ExtendedRack < Struct.new(:app) # kindly borrowed from Sinatra
    def call(env)
      result, callback = app.call(env), env['async.callback']
      return result unless callback and async?(*result)
      after_response { callback.call result }
      setup_close(env, *result)
      throw :async
    end

    private

    def setup_close(env, status, header, body)
      return unless body.respond_to? :close and env.include? 'async.close'
      env['async.close'].callback { body.close }
      env['async.close'].errback { body.close }
    end

    def after_response(&block)
      raise NotImplementedError, "only supports EventMachine at the moment" unless defined? EventMachine
      EventMachine.next_tick(&block)
    end

    def async?(status, headers, body)
      return true if status == -1
      body.respond_to? :callback and body.respond_to? :errback
    end
  end
end
