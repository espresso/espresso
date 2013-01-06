class EApp

  # Rack interface to all found controllers
  #
  # @example config.ru
  #    module App
  #      class Forum < E
  #        map '/forum'
  #
  #        # ...
  #      end
  #
  #      class Blog < E
  #        map '/blog'
  #
  #        # ...
  #      end
  #    end
  #
  #    run EApp
  def self.call env
    new(:automount).call(env)
  end

  def initialize automount = false, &proc
    @routes = {}
    @controllers = automount ? discover_controllers : []
    @mounted_controllers = []
    @controllers.each {|c| mount_controller c}
    proc && self.instance_exec(&proc)
  end

  # mount a controller or a namespace(a module, a class or a regexp) containing controllers.
  # proc given here will be executed inside given controller/namespace,
  # as well as any global setup defined before this method will be called.
  def mount namespace_or_app, *roots, &setup
    extract_controllers(namespace_or_app).each {|c| mount_controller c, *roots, &setup}
    self
  end

  # proc given here will be executed inside ALL CONTROLLERS!
  # used to setup multiple controllers at once.
  #
  # @note this method should be called before mounting controllers
  #
  # @example
  #   #class News < E
  #     # ...
  #   end
  #   class Articles < E
  #     # ...
  #   end
  #
  #   # this will work correctly
  #   app = EApp.new
  #   app.global_setup { controllers setup }
  #   app.mount News
  #   app.mount Articles
  #   app.run
  #
  #   # and this will NOT!
  #   app = EApp.new
  #   app.mount News
  #   app.mount Articles
  #   app.global_setup { controllers setup }
  #   app.run
  #
  def global_setup &proc
    @global_setup = proc
    self
  end
  alias setup_controllers global_setup
  alias setup global_setup

  # displays URLs the app will respond to,
  # with controller and action that serving each URL.
  def url_map opts = {}
    map = {}
    @mounted_controllers.each do |c|
      c.url_map.each_pair do |r, s|
        s.each_pair { |rm, as| (map[r] ||= {})[rm] = as.dup.unshift(c) }
      end
    end

    def map.to_s
      out = []
      self.each do |data|
        route, request_methods = data
        next if route.size == 0
        out << "%s\n" % route
        request_methods.each_pair do |request_method, route_setup|
          out << "  %s%s" % [request_method, ' ' * (10 - request_method.size)]
          out << "%s#%s\n" % [route_setup[0], route_setup[3]]
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
  # @example use Thin server with its default port
  #   app.run :server => :Thin
  # @example use EventedMongrel server with custom options
  #   app.run :server => :EventedMongrel, :port => 9090, :num_processors => 1000
  #
  # @param [Hash] opts
  # @option opts [Symbol]  :server (:WEBrick) web server
  # @option opts [Integer] :port   (5252)
  # @option opts [String]  :host   (0.0.0.0)
  def run opts = {}
    server = opts.delete(:server)
    (server && Rack::Handler.const_defined?(server)) || (server = HTTP__DEFAULT_SERVER)

    port = opts.delete(:port)
    opts[:Port] ||= port || HTTP__DEFAULT_PORT

    host = opts.delete(:host) || opts.delete(:bind)
    opts[:Host] = host if host

    Rack::Handler.const_get(server).run self, opts
  end

  def call env
    if rewrite_rules.any?
      status, headers, body = EspressoFrameworkRewriter.new(rewrite_rules).call(env)
      return [status, headers, body] if status
    end
    @sorted_routes ||= @routes.keys.sort {|a,b| b.source.size <=> a.source.size}
    @sorted_routes.each do |route|
      if (pi = route.match(env[ENV__PATH_INFO].to_s)) && (pi = pi[1])
        
        if route_setup = @routes[route][env[ENV__REQUEST_METHOD]]

          env[ENV__SCRIPT_NAME] = (route_setup[:path]).freeze
          env[ENV__PATH_INFO]   = (pi.empty? || pi =~ /\A\// ? pi : '/' << pi.to_s).freeze

          epi, format = nil
          (fr = route_setup[:format_regexp]) && (epi, format = pi.split(fr))
          env[ENV__ESPRESSO_PATH_INFO] = epi
          env[ENV__ESPRESSO_FORMAT]    = format

          app = Rack::Builder.new
          middleware.each {|w,a,p| app.use w, *a, &p}
          app.run route_setup[:ctrl].new(route_setup[:action])
          route_setup[:ctrl].middleware.each {|w,a,p| app.use w, *a, &p}
          p app.mw
          return app.call(env)
        end
      end
    end
    [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found: #{env[ENV__PATH_INFO]}"]]
  end

  private
  def mount_controller controller, *roots, &setup
    return if @mounted_controllers.include?(controller)

    root = roots.shift
    if root || base_url.size > 0
      controller.remap!(base_url + root.to_s, *roots)
    end

    setup && controller.class_exec(&setup)
    @global_setup && controller.class_exec(&@global_setup)
    controller.mount! self
    @routes.update controller.routes

    @mounted_controllers << controller
  end

  def discover_controllers namespace = nil
    controllers = ::ObjectSpace.each_object(::Class).
      select { |c| is_app?(c) }.reject { |c| [E].include? c }
    return controllers unless namespace

    namespace.is_a?(Regexp) ?
      controllers.select { |c| c.name =~ namespace } :
      controllers.select { |c| [c.name, c.name.split('::').last].include? namespace.to_s }
  end

  def extract_controllers namespace
    return ([namespace] + namespace.constants.map { |c| namespace.const_get(c) }).
      select { |c| is_app? c } if [Class, Module].include?(namespace.class)

    discover_controllers namespace
  end
end
