
#
# asl = assets_loader :vendor
#  
# asl.js :jquery
# #=> <script src="/vendor/jquery.js" ...
# 
# # change dir to vendor/jquery-ui
# asl.chdir 'jquery-ui'
#
# asl.js 'js/jquery-ui.min'
# #=> <script src="/vendor/jquery-ui/js/jquery-ui.min.js" ...
#
# asl.css 'css/jquery-ui.min'
# #=> <link href="/vendor/jquery-ui/css/jquery-ui.min.css" ...
#
# # change dir to vendor/bootstrap
# asl.cd '../bootstrap'
#
# asl.js 'js/bootstrap.min'
# #=> <script src="/vendor/bootstrap/js/bootstrap.min.js" ...
#
# asl.css 'css/bootstrap'
# #=> <link href="/vendor/bootstrap/css/bootstrap.css" ...
#
class EAssetsLoader

  attr_reader :baseurl, :wd, :app, :to_s
  alias :path :baseurl

  def initialize app, baseurl = nil
    @app, @wd, @to_s = app, nil, ''
    baseurl = baseurl.to_s.strip
    baseurl = app.assets_url + baseurl unless baseurl =~ /\A[\w|\d]+\:\/\/|\A\/|\A\.\//
    baseurl << '/' unless baseurl =~ /\/\Z/
    @baseurl = baseurl.freeze
  end

  def js url = nil, opts = {}
    url.is_a?(Hash) ? opts = url : opts[:src] ||= urlify(url)
    html = script_tag opts.merge(:ext => '.js')
    to_s << html
    html
  end

  def css url = nil, opts = {}
    url.is_a?(Hash) ? opts = url : opts[:src] ||= urlify(url)
    html = style_tag opts.merge(:ext => '.css')
    to_s << html
    html
  end

  %w[.jpg .jpeg .png .gif .tif .tiff .bmp .svg .ico .xpm .icon].each do |ext|
    # this can be easily done via `define_method`,
    # however, ruby 1.8 does not support args with default values on procs
    # TODO: use `define_method` when 1.8 support dropped.
    class_eval <<-RUBY
      def #{ext.delete('.')} url = nil, opts = {}
        url.is_a?(Hash) ? opts = url : opts[:src] ||= urlify(url)
        html = image_tag opts.merge(:ext => '#{ext}')
        to_s << html
        html
      end
    RUBY
  end

  def chdir path = nil
    return @wd = nil unless path
    dirs_back, path = path.to_s.split(/\/+/).partition { |c| c == '..' }
    if wd
      wd_chunks = wd.split(/\/+/)
      wd = wd_chunks[0, wd_chunks.size - dirs_back.size] || []
    else
      wd = []
    end
    @wd = (wd + path << '').
      compact. # `compact` is faster than `nil.to_s`
      join('/').freeze
    self
  end
  alias :cd :chdir

  private

  def urlify url
    baseurl + (wd||'') + (url||'')
  end

  module Mixin
    # building HTML script tag from given URL and/or opts.
    # if passing URL as first argument, 
    # it will be appended to the assets base URL, set via `assets_url` at app level.
    # 
    # if you want an unmapped URL, pass it via :src option.
    # this will avoid `assets_url` setup and use the URL as is.
    #
    # if :ext option provided, it will be appended to the final URL
    def script_tag src = nil, opts = {}, &proc
      src.is_a?(Hash) && (opts = src.dup) && (src = nil)
      opts[:type] ||= 'text/javascript'
      if proc
        "<script %s>\n%s\n</script>\n" % [__e__assets__opts_to_s(opts), proc.call]
      else
        opted_src = opts.delete(:src)
        src ||= opted_src || raise('Please provide script URL as first argument or via :src option')
        "<script src=\"%s%s\" %s></script>\n" % [
          opted_src ? opted_src : assets_url(src),
          opts.delete(:ext),
          __e__assets__opts_to_s(opts)
        ]
      end
    end

    # same as `script_tag`, except it building an style/link tag
    def style_tag src = nil, opts = {}, &proc
      src.is_a?(Hash) && (opts = src.dup) && (src = nil)
      if proc
        opts[:type] ||= 'text/css'
        "<style %s>\n%s\n</style>\n" % [__e__assets__opts_to_s(opts), proc.call]
      else
        opts[:rel] = 'stylesheet'
        opted_src = opts.delete(:href) || opts.delete(:src)
        src ||= opted_src || raise('Please URL as first argument or :href option')
        "<link href=\"%s%s\" %s />\n" % [
          opted_src ? opted_src : assets_url(src),
          opts.delete(:ext),
          __e__assets__opts_to_s(opts)
        ]
      end
    end

    # builds and HTML img tag.
    # URLs are resolved exactly as per `script_tag` and `style_tag`
    def image_tag src = nil, opts = {}
      src.is_a?(Hash) && (opts = src.dup) && (src = nil)
      opted_src = opts.delete(:src)
      src ||= opted_src || raise('Please provide image URL as first argument or :src option')
      opts[:alt] ||= ::File.basename(src, ::File.extname(src))
      "<img src=\"%s%s\" %s />\n" % [
        opted_src ? opted_src : assets_url(src),
        opts.delete(:ext),
        __e__assets__opts_to_s(opts)
      ]
    end
    alias img_tag image_tag

    private
    def assets_url path = nil
      app.assets_url + (path||'')
    end

    def __e__assets__opts_to_s opts
      (@__e__assets__opts_to_s ||= {})[opts.hash] = opts.keys.inject([]) do |f, k|
        f << '%s="%s"' % [k, ::CGI.escapeHTML(opts[k])]
      end.join(' ')
    end
  end
  include Mixin
end

class EApp
  module Setup

    # set the baseurl for assets.
    # by default, assets URL is empty.
    # 
    # @example assets_url not set
    #   script_tag 'master.js'
    #   => <script src="master.js"
    #   style_tag 'theme.css'
    #   => <link href="theme.css"
    #
    # @example assets_url set to /assets
    #
    #   script_tag 'master.js'
    #   => <script src="/assets/master.js"
    #   style_tag 'theme.css'
    #   => <link href="/assets/theme.css"
    #
    # @note
    #   if second argument given, Espresso will reserve given URL for serving assets,
    #   so make sure it does not interfere with your actions.
    #
    # @example
    #
    # class App < E
    #   map '/'
    #
    #   # actions inside controller are not affected 
    #   # cause app is not set to serve assets, thus no URLs are reserved.
    #   
    # end
    #
    # app = EApp.new do
    #   assets_url '/'
    #   mount App
    # end
    # app.run
    #
    #
    # @example
    #
    # class App < E
    #   map '/'
    #   
    #   # no action here will work cause "/" URL is reserved for assets
    #   
    # end
    #
    # app = EApp.new do
    #   assets_url '/', :serve
    #   mount App
    # end
    # app.run
    #
    # @example
    #
    # class App < E
    #   map '/'
    #  
    #   def assets
    #     # this action wont work cause "/assets" URL is reserved for assets
    #   end
    #
    #   # other actions will work properly
    #  
    # end
    #
    # app = EApp.new do
    #   assets_url '/assets', :serve
    #   mount App
    # end
    # app.run
    #
    def assets_url url = nil, serve = nil
      if (url = url.to_s.strip).length > 0
        assets_url     = url =~ /\A[\w|\d]+\:\/\// ? url : rootify_url(url)
        @assets_url    = (assets_url =~ /\/\Z/ ? assets_url : '' << assets_url << '/').freeze
        @assets_server = serve
      end
      @assets_url ||= ''
    end
    alias assets_map assets_url

    def assets_server?
      @assets_server
    end

    # used when app is set to serve assets.
    # by default, Espresso will serve files found under public/ folder inside app root.
    # use `assets_path` at class level to set custom path.
    #
    # @note `assets_path` is used to set paths relative to app root.
    #       to set absolute path to assets, use `assets_fullpath` instead.
    #
    def assets_path path = nil
      @assets_path = root + normalize_path(path).freeze if path
      @assets_path ||= '' << root << 'public/'.freeze
    end

    def assets_fullpath path = nil
      @assets_fullpath = normalize_path(path).freeze if path
      @assets_fullpath
    end

  end

end

class E
  include EAssetsLoader::Mixin

  def assets_loader baseurl = nil
    EAssetsLoader.new app, baseurl
  end

end
