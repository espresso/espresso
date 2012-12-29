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
    @controllers = automount ? discover_controllers : []
    @mounted_controllers = []
    @controllers.each {|c| mount_controller c}
    @inner_apps = []
    proc && self.instance_exec(&proc)
  end

  # mount a controller or a namespace(a module, a class or a regexp) containing controllers.
  # proc given here will be executed inside given controller/namespace,
  # as well as any global setup defined before this method called.
  #
  def mount namespace_or_app, *roots, &setup
    if namespace_or_app.respond_to?(:call) && !is_app?(namespace_or_app)
      # seems a Rack app given
      roots.empty? && raise(ArgumentError, "Please provide at least one root to mount given app on")
      @inner_apps << [namespace_or_app, roots] # setup ignored on Rack apps
    else
      extract_controllers(namespace_or_app).each {|c| mount_controller c, *roots, &setup}
    end
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
  #   app.run :server => :EventedMongrel, :Port => 9090, :num_processors => 1000
  #
  # @param [Hash] opts
  def run opts = {}
    server = opts.delete(:server)
    (server && Rack::Handler.const_defined?(server)) || (server = HTTP__DEFAULT_SERVER)
    handler =  Rack::Handler.const_get(server)
    if handler.respond_to?(:valid_options) && handler.valid_options.any? {|k,v| k =~ /\APort/}
      opts[:Port] ||= HTTP__DEFAULT_PORT
    end
    handler.run app, opts
  end

  # Rack interface to mounted controllers
  def call env
    app.call env
  end

  def app
    @app ||= builder
  end
  alias to_app app

  def ipcm_trigger(*)
    warn "This trigger is just a placeholder. 
      To use Inter-Process Cache Manager please install and load e-toolkit gem"
  end

  private
  def builder
    app, builder = self, Rack::Builder.new
    middleware.each { |w| builder.use w[0], *w[1], &w[2] }
    if rewrite_rules.any?
      EspressoFrameworkRewriter.rules = rewrite_rules.freeze
      builder.use EspressoFrameworkRewriter
    end
    @mounted_controllers.each do |ctrl|
      ctrl.url_map.each_key do |route|
        builder.map route do
          ctrl.middleware.each { |w| use w[0], *w[1], &w[2] }
          run ctrl
        end
      end
    end
    @inner_apps.each do |a|
      inner_app, inner_app_roots = a
      inner_app_roots.each do |inner_app_root|
        builder.map(inner_app_root) { run inner_app }
      end
    end
    builder.to_app
  end

  def mount_controller controller, *roots, &setup
    return if @mounted_controllers.include?(controller)

    root = roots.shift
    if root || base_url.size > 0
      controller.remap!(base_url + root.to_s, *roots)
    end
      
    setup && controller.class_exec(&setup)
    @global_setup && controller.class_exec(&@global_setup)
    controller.mount! self

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
