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
    @automount = automount
    @controllers, @mounted_controllers, @inner_apps = [], [], []
    proc && self.instance_exec(&proc)
  end

  # add controller/namespace to be mounted when app starts.
  # proc given here will be executed inside given controller/namespace.
  def mount namespace_or_app, *roots, &setup
    if namespace_or_app.respond_to?(:call) && !is_app?(namespace_or_app)
      # seems a Rack app given
      roots.empty? && raise(ArgumentError, "Please provide at least one root to mount given app on")
      @inner_apps << [namespace_or_app, roots] # setup ignored on Rack apps
    else
      @controllers << [namespace_or_app, roots, setup]
    end
    self
  end

  # mount controller/namespace right away rather than at app starting.
  # proc given here will be executed inside given controller/namespace.
  def mount! namespace, *roots, &setup
    root = roots.shift
    extract_controllers(namespace).each do |ctrl|
      root && ctrl.remap!(root, *roots)
      ctrl.app = self
      ctrl.setup!
      ctrl.global_setup!(&setup) if setup
      ctrl.global_setup!(&@global_setup) if @global_setup
      ctrl.map!
      @mounted_controllers << ctrl
    end
    self
  end

  # proc given here will be executed inside ALL CONTROLLERS!
  def setup_controllers &proc
    @global_setup = proc
    self
  end
  alias setup setup_controllers

  # displays URLs the app will respond to,
  # with controller and action that serving each URL.
  def url_map opts = {}
    mount_controllers!

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
  #   app.run server: :Thin
  # @example use EventedMongrel server with custom options
  #   app.run server: :EventedMongrel, Port: 9090, num_processors: 1000
  #
  # @param [Hash] opts
  def run opts = {}
    mount_controllers!
    server = opts.delete(:server)
    (server && ::Rack::Handler.const_defined?(server)) || (server = DEFAULT_SERVER)
    handler =  ::Rack::Handler.const_get(server)
    if handler.respond_to?(:valid_options) && handler.valid_options.any? {|k,v| k =~ /\APort/}
      opts[:Port] ||= DEFAULT_PORT
    end
    handler.run self, opts
  end

  # Rack interface
  def call env
    app.call env
  end

  def app
    @app ||= builder
  end

  alias to_app app

  private
  def builder
    app, builder = self, ::Rack::Builder.new
    use.each { |w| builder.use w[:ware], *w[:args], &w[:proc] }
    mount_controllers!
    @mounted_controllers.each do |ctrl|
      ctrl.url_map.each_pair do |route, rest_map|
        builder.map route do
          ctrl.use?.each { |w| use w[:ware], *w[:args], &w[:proc] }
          run lambda { |env| ctrl.new.call env }
        end
      end
      ctrl.freeze!
      ctrl.lock!
    end
    @inner_apps.each do |a|
      inner_app, inner_app_roots = a
      inner_app_roots.each do |inner_app_root|
        builder.map(inner_app_root) { run inner_app }
      end
    end
    if assets_server?
      builder.map assets_url do
        run lambda { |e| ::Rack::Directory.new(app.assets_fullpath || app.assets_path).call(e) }
      end
    end
    rewrite_rules.size > 0 ?
      ::AppetiteRewriter.new(rewrite_rules, builder.to_app) :
      builder.to_app
  end

  def mount_controllers!
    @automount &&
      @controllers += discover_controllers.map { |c| [c, ['/'], nil] }

    @controllers.each do |ctrl_setup|
      ctrl, roots, setup = ctrl_setup
      next if @mounted_controllers.include?(ctrl)
      mount! ctrl, *roots, &setup
    end
  end

  def discover_controllers namespace = nil
    controllers = ::ObjectSpace.each_object(::Class).
        select { |c| is_app?(c) }.
        reject { |c| [::Appetite, ::AppetiteRewriter, ::E].include? c }
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

class << E

  # @api semi-public
  #
  # remap served root(s) by prepend given path to controller's root and canonical paths
  #
  # @note Important: all actions should be defined before re-mapping
  #
  def remap! root, *canonicals
    return if locked?
    base_url = root.to_s + '/' + base_url()
    new_canonicals = [] + canonicals
    canonicals().each do |ec|
      # each existing canonical should be prepended with new root
      new_canonicals << base_url + '/' + ec.to_s
      # as well as with each given canonical
      canonicals.each do |gc|
        new_canonicals << gc.to_s + '/' + ec.to_s
      end
    end
    map base_url, *new_canonicals
  end

  def global_setup! &setup
    return unless setup
    @global_setup = true
    setup.arity == 1 ?
        self.class_exec(self, &setup) :
        self.class_exec(&setup)
    setup!
    @global_setup = false
  end

  def global_setup?
    @global_setup
  end

  def mount *roots, &setup
    return app if app
    locked? && raise(SecurityError, 'App was previously locked, so you can not remount it or change any setup.')
    ::EApp.new.mount self, *roots, &setup
  end
  alias mount!  mount
  alias to_app  mount
  alias to_app! mount

  def call env
    mount.call env
  end

  def run *args
    mount.run *args
  end

  # @api semi-public
  def app= app
    return if locked?
    @app = app
    # overriding @base_url by prepending app's base URL.
    # IMPORTANT: @base_url is a var set by Appetite,
    # so make sure when this name is changed in Appetite it is also changed here
    @base_url = @app.base_url + base_url
  end

  def app
    @app
  end

  def session(*)
    raise 'Please use `%s` at app level only' % __method__
  end

  def rewrite(*)
    raise 'Please use `%s` at app level only' % __method__
  end
  alias rewrite_rule rewrite
end

class E

  def app
    self.class.app
  end

  def app_root
    app.root
  end

end
