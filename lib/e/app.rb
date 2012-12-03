class EApp

  include ::AppetiteUtils

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
    new.call env
  end

  module Setup

    # set base URL to be prepended to all controllers
    def map url
      @base_url = rootify_url(url).freeze
    end

    def base_url
      @base_url || ''
    end

    # set/get app root
    def root path = nil
      @root = ('%s/' % path).sub(/\/+\Z/, '/').freeze if path
      @root ||= (::Dir.pwd << '/').freeze
    end
    alias app_root root

    # allow app to use sessions.
    #
    # @example keep sessions in memory
    #    class App < E
    #      # ...
    #    end
    #    app = EApp.new
    #    app.session :memory
    #    app.run
    #
    # @example keep sessions in memory using custom options
    #    class App < E
    #      # ...
    #    end
    #    app = EApp.new
    #    app.session :memory, :domain => 'foo.com', :expire_after => 2592000
    #    app.run
    #
    # @example keep sessions in cookies
    #    class App < E
    #      # ...
    #    end
    #    app = EApp.new
    #    app.session :cookies
    #    app.run
    #
    # @example keep sessions in memcache
    #    class App < E
    #      # ...
    #    end
    #    app = EApp.new
    #    app.session :memcache
    #    app.run
    #
    # @example use a custom pool, i.e. github.com/migrs/rack-session-mongo
    #    #> gem install rack-session-mongo
    #
    #    class App < E
    #      # ...
    #    end
    #
    #    require 'rack/session/mongo'
    #
    #    app = EApp.new
    #    app.session Rack::Session::Mongo
    #    app.run
    #
    # @param [Symbol, Class] use
    # @param [Array] args
    def session use, *args
      args.unshift case use
                     when :memory
                       ::Rack::Session::Pool
                     when :cookies
                       ::Rack::Session::Cookie
                     when :memcache
                       ::Rack::Session::Memcache
                     else
                       use
                   end
      use(*args)
    end

    # set authorization at app level.
    # any controller/action will be protected.
    def basic_auth opts = {}, &proc
      use ::Rack::Auth::Basic, opts[:realm] || opts['realm'], &proc
    end
    alias auth basic_auth

    # (see #basic_auth)
    def digest_auth opts = {}, &proc
      opts[:realm]  ||= 'AccessRestricted'
      opts[:opaque] ||= opts[:realm]
      use ::Rack::Auth::Digest::MD5, opts, &proc
    end

    # middleware declared here will be used on all controllers.
    #
    # especially, here should go middleware that changes app state,
    # which wont work if defined inside controller.
    #
    # you can of course define any type of middleware at app level,
    # it is even recommended to do so to avoid redundant
    # middleware declaration at controllers level.
    #
    # @example
    #
    #    class App < E
    #      # ...
    #    end
    #    app = EApp.new
    #    app.use SomeMiddleware, :with, :some => :opts
    #    app.run
    #
    # Any middleware that does not change app state,
    # i.e. non-upfront middleware, can be defined inside controllers.
    #
    # @note middleware defined inside some controller will run only for that controller.
    #       to have global middleware, define it at app level.
    #
    # @example defining middleware at app level
    #    module App
    #      class Forum < E
    #        map '/forum'
    #        # ...
    #      end
    #
    #      class Blog < E
    #        map '/blog'
    #        # ...
    #      end
    #    end
    #
    #    app = EApp.new
    #    app.use Rack::CommonLogger
    #    app.use Rack::ShowExceptions
    #    app.run
    #
    def use ware = nil, *args, &proc
      @middleware ||= []
      @middleware << {:ware => ware, :args => args, :proc => proc} if ware
      @middleware
    end

    # declaring rewrite rules.
    #
    # first argument should be a regex and a proc should be provided.
    #
    # the regex(actual rule) will be compared against Request-URI,
    # i.e. current URL without query string.
    # if some rule depend on query string,
    # use `params` inside proc to determine either some param was or not set.
    #
    # the proc will decide how to operate when rule matched.
    # you can do:
    # `redirect('location')`
    #     redirect to new location using 302 status code
    # `permanent_redirect('location')`
    #     redirect to new location using 301 status code
    # `pass(controller, action, any, params, with => opts)`
    #     pass control to given controller and action without redirect.
    #     consequent params are used to build URL to be sent to given controller.
    # `halt(status|body|headers|response)`
    #     send response to browser without redirect.
    #     accepts an arbitrary number of arguments.
    #     if arg is an Integer, it will be used as status code.
    #     if arg is a Hash, it is treated as headers.
    #     if it is an array, it is treated as Rack response and are sent immediately, ignoring other args.
    #     any other args are treated as body.
    #
    # @note any method available to controller instance are also available inside rule proc.
    #       so you can fine tune the behavior of any rule.
    #       ex. redirect on GET requests and pass control on POST requests.
    #       or do permanent redirect for robots and simple redirect for browsers etc.
    #
    # @example
    #    app = EApp.new
    #
    #    # redirect to new address
    #    app.rewrite /\A\/(.*)\.php$/ do |title|
    #      redirect Controller.route(:index, title)
    #    end
    #
    #    # permanent redirect
    #    app.rewrite /\A\/news\/([\w|\d]+)\-(\d+)\.html/ do |title, id|
    #      permanent_redirect Forum, :posts, :title => title, :id => id
    #    end
    #
    #    # no redirect, just pass control to News controller
    #    app.rewrite /\A\/latest\/(.*)\.html/ do |title|
    #      pass News, :index, :scope => :latest, :title => title
    #    end
    #
    #    # Return arbitrary body, status-code, headers, without redirect:
    #    # If argument is a hash, it is added to headers.
    #    # If argument is a Integer, it is treated as Status-Code.
    #    # Any other arguments are treated as body.
    #    app.rewrite /\A\/archived\/(.*)\.html/ do |title|
    #      if page = Model::Page.first(:url => title)
    #        halt page.content, 'Last-Modified' => page.last_modified.to_rfc2822
    #      else
    #        halt 404, 'page not found'
    #      end
    #    end
    #
    #    app.run
    #
    def rewrite rule = nil, &proc
      rewrite_rules << [rule, proc] if proc
    end

    alias rewrite_rule rewrite

    def rewrite_rules
      @rewrite_rules ||= []
    end

    def pids_reader &proc
      return @pids_reader if @pids_reader
      if proc.is_a?(Proc)
        @pids_reader = proc
        register_ipcm_signal
      end
    end
    alias pids pids_reader
  end
  include Setup

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

  # by default, Espresso will use WEBrick server and default WEBrick port.
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
    server && ::Rack::Handler.const_defined?(server) || (server = :WEBrick)
    ::Rack::Handler.const_get(server).run self, opts
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
end
