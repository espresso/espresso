class EBuilder
  include EUtils
  include EConstants

  def self.call env
    new(:automount).call(env)
  end

  attr_reader :controllers, :mounted_controllers

  # creates new Espresso app.
  # 
  # @param automount  if set to any positive value(except Class, Module or Regexp),
  #                   all found controllers will be mounted,
  #                   if set to a Class, Module or Regexp,
  #                   only controllers under given namespace will be mounted.
  # @param [Proc] proc if block given, it will be executed inside newly created app
  #
  def initialize automount = false, &proc
    @routes = []
    @controllers, @subcontrollers = {}, []
    @hosts, @controllers_hosts = {}, {}
    @automount = automount
    proc && self.instance_exec(&proc)
    use ExtendedRack
    compiler_pool(Hash.new)
  end

  # mount given/discovered controllers into current app.
  # any number of arguments accepted.
  # String arguments are treated as roots/canonicals.
  # any other arguments are used to discover controllers.
  # controllers can be passed directly
  # or as a Module that contain controllers
  # or as a Regexp matching controller's name.
  # 
  # proc given here will be executed inside given/discovered controllers
  def mount *args, &setup
    root, controllers, applications = nil, [], []
    opts = args.last.is_a?(Hash) ? args.pop : {}
    args.flatten.each do |a|
      if a.is_a?(String)
        root = rootify_url(a)
      elsif is_app?(a)
        controllers << a
      elsif a.respond_to?(:call)
        applications << a
      else
        controllers.concat extract_controllers(a)
      end
    end
    controllers.each do |c|
      @controllers[c] = [root, opts, setup]
      c.subcontrollers.each do |sc|
        mount(sc, root.to_s + c.base_url, opts)
        @subcontrollers << sc
      end
    end
    
    mount_applications applications, root, opts

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
  alias setup             global_setup

  def environment
    ENV[ENV__RACK_ENV] || :development
  end

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
    boot!

    handler = opts.delete(:server)
    (handler && Rack::Handler.const_defined?(handler)) || (handler = HTTP__DEFAULT_SERVER)

    port = opts.delete(:port)
    opts[:Port] ||= port || HTTP__DEFAULT_PORT

    host = opts.delete(:host) || opts.delete(:bind)
    opts[:Host] = host if host

    $stderr.puts "\n--- Starting Espresso for %s on %s port backed by %s server ---\n\n" % [
      environment, opts[:Port], handler
    ]
    Rack::Handler.const_get(handler).run app, opts do |server|
      %w[INT TERM].each do |sig|
        Signal.trap(sig) do
          $stderr.puts "\n--- Stopping Espresso... ---\n\n"
          server.respond_to?(:stop!) ? server.stop! : server.stop
        end
      end
      server.threaded = opts[:threaded] if server.respond_to? :threaded=
      yield server if block_given?
    end
  end

  def call env
    app.call env
  end

  def app
    @app ||= begin
      on_boot!
      mount_controllers!
      @sorted_routes = sorted_routes.freeze
      @routes.freeze
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
    path_info, script_name = env[ENV__PATH_INFO], env[ENV__SCRIPT_NAME]
    env[ENV__ESPRESSO_GATEWAYS] = []
    @sorted_routes.each do |(route,overall_setup)|
      next unless matches = route.match(path_info)

      if rewriter?(overall_setup) # rewriter works only on GET and HEAD requests
        next unless route_setup = valid_rewriter_context?(overall_setup, env[ENV__REQUEST_METHOD])
      else
        unless route_setup = valid_route_context?(overall_setup, env[ENV__REQUEST_METHOD])
          return not_implemented overall_setup.keys.join(', ')
        end
      end

      next unless unit = [:controller, :rewriter, :application].find {|u| route_setup[u]}
      response = self.send('call_' + unit.to_s, env, route_setup, matches)
      return response unless response[0] == STATUS__PASS
      env[ENV__PATH_INFO], env[ENV__SCRIPT_NAME] = path_info, script_name
      env[ENV__ESPRESSO_GATEWAYS].push(route_setup[:action])
      next
    end
    not_found(env)
  ensure
    env[ENV__PATH_INFO], env[ENV__SCRIPT_NAME] = path_info, script_name
  end

  def call_rewriter env, route_setup, matches
    return not_found(env) unless valid_host?(@hosts.merge(@controllers_hosts), env)
    ERewriter.new(*matches.captures, &route_setup[:rewriter]).call(env)
  end

  def call_application env, route_setup, matches
    return not_found(env) unless valid_host?(@hosts.merge(@controllers_hosts), env)
    env[ENV__PATH_INFO] = normalize_path( matched_path_info(matches) )
    route_setup[:application].call(env)
  end

  def call_controller env, route_setup, matches
    return not_found(env) unless valid_host?(@hosts.merge(route_setup[:controller].hosts), env)

    format, path_info = handle_format(route_setup[:formats], matched_path_info(matches))
    env[ENV__ESPRESSO_FORMAT] = format
    env[ENV__PATH_INFO] = normalize_path(path_info)
    env[ENV__SCRIPT_NAME] = route_setup[:path].freeze

    controller_instance = route_setup[:controller].new
    controller_instance.action_setup = route_setup
    app = Rack::Builder.new
    app.run controller_instance
    route_setup[:controller].middleware.each {|w,a,p| app.use w, *a, &p}
    app.call(env)
  end

  def mount_controllers!
    automount! if @automount
    @mounted_controllers = []
    @controllers.each_pair {|c,(root,opts,setup)| mount_controller(c, root, opts, &setup)}
  end

  def mount_controller controller, root = nil, opts = {}, &setup
    return if @mounted_controllers.include?(controller)
    root.is_a?(Hash) && (opts = root) && (root = nil)

    if root || base_url.size > 0
      controller.remap!(base_url + root.to_s, opts)
    end

    unless @subcontrollers.include?(controller)
      @global_setup && controller.global_setup!(&@global_setup)
      setup && controller.external_setup!(&setup)
    end

    controller.mount! self

    index_routes = index_routes(controller)
    controller.routes.each_pair do |route,route_setup|
      @routes << [route, route_setup, (index_routes[route] || 2)]
    end
    @controllers_hosts.update controller.hosts
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

  def mount_applications applications, root = nil, opts = {}
    applications = [applications] unless applications.is_a?(Array)
    applications.compact!
    return if applications.empty?
    root.is_a?(Hash) && (opts = root) && (root = nil)

    request_methods = (opts[:on] || opts[:request_method] || opts[:request_methods])
    request_methods = [request_methods] unless request_methods.is_a?(Array)
    request_methods.compact!
    request_methods.map! {|m| m.to_s.upcase}.reject! do |m|
      HTTP__REQUEST_METHODS.none? {|lm| lm == m}
    end
    request_methods = HTTP__REQUEST_METHODS if request_methods.empty?

    route = route_to_regexp(rootify_url(root || '/'), skip_boundary_check: true)
    applications.each do |a|
      route_setup = request_methods.inject({}) do |map,m|
        map.merge(m => {application: a})
      end
      @routes << [route, route_setup, 1]
    end
  end
  alias mount_application mount_applications

  # execute blocks defined via `on_boot`
  def on_boot!
    (@on_boot || []).each {|b| b.call}
  end

end
