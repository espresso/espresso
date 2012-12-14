class EspressoFrameworkAssetsLoader

  attr_reader :baseurl, :wd, :app, :to_s

  # @example
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
  # @example using blocks. blocks are converted to string automatically
  #
  # # `assets_url` is set to /vendor at app level
  #
  # assets_loader do
  #   
  #   js :jquery
  #
  #   chdir 'jquery-ui'
  #   js 'js/jquery-ui.min'
  #   css 'css/jquery-ui.min'
  #
  #   cd '../bootstrap'
  #   js 'js/bootstrap.min'
  #   css 'css/bootstrap'
  # end
  #
  # #=> <script src="/vendor/jquery.js" ...
  # #=> <script src="/vendor/jquery-ui/js/jquery-ui.min.js" ...
  # #=> <link href="/vendor/jquery-ui/css/jquery-ui.min.css" ...
  # #=> <script src="/vendor/bootstrap/js/bootstrap.min.js" ...
  # #=> <link href="/vendor/bootstrap/css/bootstrap.css" ...
  def initialize ctrl, baseurl = nil, &proc
    @ctrl, @app  = ctrl, ctrl.app
    @tags, @to_s = [], ''
    baseurl = baseurl.to_s.strip
    baseurl = app.assets_url + baseurl unless baseurl =~ /\A[\w|\d]+\:\/\/|\A\/|\A\.\//
    baseurl << '/' unless baseurl =~ /\/\Z/
    @baseurl, @wd = baseurl.freeze, nil
    proc && self.instance_exec(&proc)
  end

  def js *args
    to_html :script_tag, '.js', *args
  end

  def css *args
    to_html :style_tag, '.css', *args
  end

  %w[.jpg .jpeg .png .gif .tif .tiff .bmp .svg .ico .xpm .icon].each do |ext|
    define_method ext.delete('.') do |*args|
      to_html :image_tag, ext, *args
    end
  end

  def chdir path = nil
    return @wd = nil unless path
    
    wd = []
    if (path = path.to_s) =~ /\A\//
      path = path.sub(/\A\/+/, '')
      path = path.empty? ? [] : [path]
    else
      dirs_back, path = path.split(/\/+/).partition { |c| c == '..' }
      if @wd
        wd_chunks = @wd.split(/\/+/)
        wd = wd_chunks[0, wd_chunks.size - dirs_back.size] || []
      end
    end
    @wd = (wd + path << '').
      compact. # `compact` is faster than `nil.to_s`
      join('/').freeze
    self
  end
  alias :cd :chdir

  def to_a
    @tags.map { |e| e.strip }
  end

  def method_missing *args, &proc
    @ctrl.send *args, &proc
  end

  private
  def to_html meth, ext, *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    if args.size > 0
      opts.delete :src
    else
      args = [opts[:src]] || raise(ArgumentError, 'Please provide file(s) to load via arguments or via :src option')
    end
    html = ''
    args.each do |url|
      url_opts = opts.merge(:ext => ext)
      url_opts[:src] ||= urlify(url)
      # url not passed cause files always explicitly loaded via :src option
      tag = send(meth, url_opts)
      @tags << tag
      # we could simply do `@to_a.join` 
      # but  this becomes expensive as number of tags grows.
      # `<<` instead is cheap enough to be used on each tag.
      @to_s << tag
      html  << tag
    end
    html
  end

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
        "<link href=\"%s%s\" %s>\n" % [
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
      "<img src=\"%s%s\" %s>\n" % [
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

class E
  include EspressoFrameworkAssetsLoader::Mixin

  def assets_loader(baseurl = nil, &proc)
    EspressoFrameworkAssetsLoader.new(self, baseurl, &proc)
  end

end
