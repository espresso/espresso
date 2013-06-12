class EBuilder

  # set base URL to be prepended to all controllers
  def map url, opts = {}
    url.is_a?(Hash) && (opts = url) && (url = '')
    @base_url = rootify_url(url).freeze
    @hosts    = extract_hosts(opts)
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
  #    app = E.new
  #    app.session :memory
  #    app.run
  #
  # @example keep sessions in memory using custom options
  #    class App < E
  #      # ...
  #    end
  #    app = E.new
  #    app.session :memory, :domain => 'foo.com', :expire_after => 2592000
  #    app.run
  #
  # @example keep sessions in cookies
  #    class App < E
  #      # ...
  #    end
  #    app = E.new
  #    app.session :cookies
  #    app.run
  #
  # @example keep sessions in memcache
  #    class App < E
  #      # ...
  #    end
  #    app = E.new
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
  #    app = E.new
  #    app.session Rack::Session::Mongo
  #    app.run
  #
  # @param [Symbol, Class] use
  # @param [Array] args
  def session use, *args
    args.unshift case use
                   when :memory
                     Rack::Session::Pool
                   when :cookies
                     Rack::Session::Cookie
                   when :memcache
                     Rack::Session::Memcache
                   else
                     use
                 end
    use(*args)
  end

  # set authorization at app level.
  # any controller/action will be protected.
  def basic_auth opts = {}, &proc
    use Rack::Auth::Basic, opts[:realm] || 'AccessRestricted', &proc
  end
  alias auth basic_auth

  # (see #basic_auth)
  def digest_auth opts = {}, &proc
    opts[:realm]  ||= 'AccessRestricted'
    opts[:opaque] ||= opts[:realm]
    use Rack::Auth::Digest::MD5, opts, &proc
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
  #    app = E.new
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
  #    app = E.new
  #    app.use Rack::CommonLogger
  #    app.use Rack::ShowExceptions
  #    app.run
  #
  def use ware, *args, &block
    middleware << proc { |app| ware.new(app, *args, &block) }
  end

  def middleware
    @middleware ||= []
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
  # `pass`
  #     if `pass` called without arguments
  #     the control will be passed to next matched route
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
  #    app = E.new
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
  #    # pass control to next matching route
  #    app.rewrite /\A\/+(.*)/ do |url|
  #      if target = Redirects.where(source: url).first
  #        redirect target.url
  #      end
  #      pass # move to next matching route
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
  def rewrite rule, &proc
    proc || raise(ArgumentError, "Rewrite rules requires a block to run")
    @routes << [rule, {HTTP__DEFAULT_REQUEST_METHOD => {rewriter: proc}}, 0]
  end
  alias rewrite_rule rewrite

  # by default Espresso will use EventMachine for streaming,
  # but it also supports Celluloid, when Reel web-server used.
  # use this method to set Celluloid as streaming backend.
  #
  # @example
  #   app = E.new do
  #     streaming_backend :Celluloid
  #   end
  #
  def streaming_backend backend = nil
    @streaming_backend = backend
    def streaming_backend
      @streaming_backend
    end
  end

  # block(s) to run just before application starts.
  #
  # @example
  #
  #   app = E.new do # block to run at application initialization
  #     # ...
  #   end
  #
  #   app.on_boot do # block to run lately, just before web server started
  #     # ...
  #   end
  #
  def on_boot &proc
    (@on_boot ||= []).push(proc)
  end

end
