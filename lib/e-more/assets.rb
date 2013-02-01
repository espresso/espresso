module EspressoAssetsMixin
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
  
  def js_tag src = nil, opts = {}, &proc
    src.is_a?(Hash) && (opts = src.dup) && (src = nil)
    script_tag src, opts.merge(:ext => '.js'), &proc
  end

  # same as `script_tag`, except it building a style/link tag
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

  def css_tag src = nil, opts = {}, &proc
    src.is_a?(Hash) && (opts = src.dup) && (src = nil)
    style_tag src, opts.merge(:ext => '.css'), &proc
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

  %w[.jpg .jpeg .png .gif .tif .tiff .bmp .svg .ico .xpm .icon].each do |ext|
    self.class_eval <<-RB
      def #{ext.delete('.') + '_tag'} src = nil, opts = {}
        src.is_a?(Hash) && (opts = src.dup) && (src = nil)
        image_tag src, opts.merge(:ext => '#{ext}')
      end
    RB
  end

  private
  def __e__assets__opts_to_s opts
    (@__e__assets__opts_to_s ||= {})[opts.hash] = opts.keys.inject([]) do |f, k|
      f << '%s="%s"' % [k, ::CGI.escapeHTML(opts[k])]
    end.join(' ')
  end
end

class EspressoAssetsMapper
  include EspressoAssetsMixin

  attr_reader :baseurl, :wd

  # @example
  # 
  #   assets_mapper :vendor do
  #     
  #     js_tag :jquery
  # 
  #     chdir 'jquery-ui'
  #     js_tag 'js/jquery-ui.min'
  #     css_tag 'css/jquery-ui.min'
  # 
  #     cd '../bootstrap'
  #     js_tag 'js/bootstrap.min'
  #     css_tag 'css/bootstrap'
  #   end
  #
  #   #=> <script src="/vendor/jquery.js" ...
  #   #=> <script src="/vendor/jquery-ui/js/jquery-ui.min.js" ...
  #   #=> <link href="/vendor/jquery-ui/css/jquery-ui.min.css" ...
  #   #=> <script src="/vendor/bootstrap/js/bootstrap.min.js" ...
  #   #=> <link href="/vendor/bootstrap/css/bootstrap.css" ...
  #
  def initialize baseurl, &proc
    @tags, @to_s = [], ''
    baseurl = baseurl.to_s.strip
    if baseurl.size > 0
      baseurl << '/' unless baseurl =~ /\/\Z/
    end
    @baseurl, @wd = baseurl.freeze, nil
    proc && self.instance_exec(&proc)
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
  end
  alias :cd :chdir

  private
  def assets_url path = nil
    baseurl + wd.to_s + path.to_s
  end

end

class E
  include EspressoAssetsMixin

  def assets *args, &proc
    app.assets *args, &proc
  end

  def assets_mapper *args, &proc
    EspressoAssetsMapper.new *args, &proc
  end

  private
  def assets_url path = nil
    path ?
      (app.assets_url ? app.assets_url + path.to_s : path.to_s) :
      (app.assets_url ? app.assets_url : '')
  end

end

class EspressoApp

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
  #   by default, Sprockets will be used to serve static files.
  #   to disable this, set second argument to false.
  #
  def assets_url url = nil, server = true
    return @assets_url unless url
    url = url.to_s.strip
    url = url =~ /\A[\w|\d]+\:\/\//i ? url : rootify_url(url)
    @assets_url = (url =~ /\/\Z/ ? url : String.new(url) << '/').freeze
    if server
      require 'sprockets'
      @routes[route_to_regexp(@assets_url)] = {'GET' => {:app => assets}}
    end
  end
  alias assets_map assets_url

  def assets
    @sprockets_env ||= Sprockets::Environment.new(root)
  end

end
