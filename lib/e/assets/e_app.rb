class EApp

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
    @assets_path = (root + path.to_s).freeze if path
    @assets_path ||= (root + 'public/').freeze
  end

  def assets_fullpath path = nil
    @assets_fullpath = path.to_s.freeze if path
    @assets_fullpath
  end

end
