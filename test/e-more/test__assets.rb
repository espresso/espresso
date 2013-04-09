module EMoreTest__Assets

  class App < E

    def image_with_url url = nil
      image_tag url||params[:url]
    end

    def image_with_src src
      image_tag src: src
    end
    
    def image_with_suffix url, suffix
      image_tag url, suffix: suffix
    end

    def script_with_url url = nil
      script_tag url||params[:url]
    end

    def script_with_src src
      script_tag :src => src
    end

    def script_with_suffix url, suffix
      script_tag url, suffix: suffix
    end

    def script_with_block
      script_tag params do
        params.inspect
      end
    end

    def style_with_url url = nil
      style_tag url||params[:url]
    end

    def style_with_src src
      style_tag src: src
    end

    def style_with_suffix src, suffix
      style_tag src: src, suffix: suffix
    end

    def style_with_block
      style_tag params do
        params.inspect
      end
    end

  end

  Spec.new self do
    assets_url = '/assets'
    app = E.new do
      assets_url(assets_url)
    end.mount(App)
    app(app)
    map App.base_url

    def match? response, str
      check(response.respond_to?(:body) ? response.body : response) =~
        (str.is_a?(Regexp) ? str : Regexp.new(Regexp.escape str))
    end

    Testing :image_tag do

      get :image_with_url, 'image.jpg'
      does(last_response).match? '<img src="/assets/image.jpg">'

      get :image_with_src, 'image.jpg'
      does(last_response).match? '<img src="image.jpg">'

      get :image_with_suffix, 'image.jpg', '-aloha'
      does(last_response).match? '<img src="/assets/image.jpg-aloha">'

      Should 'avoid double slashing' do
        get :image_with_url, url: '/image.jpg'
        does(last_response).match? '<img src="/assets/image.jpg">'
      end
    end

    Testing :script_tag do

      get :script_with_url, 'url.js'
      does(last_response).match?  '<script src="/assets/url.js" type="text/javascript"></script>'

      get :script_with_src, 'src.js'
      does(last_response).match? '<script src="src.js" type="text/javascript"></script>'

      get :script_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) =~ /some="param"/
      check(lines[0]) =~ /type="text\/javascript"/
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</script>'

      get :script_with_suffix, 'url.js', '-aloha'
      does(last_response).match?  '<script src="/assets/url.js-aloha" type="text/javascript"></script>'

      Should 'avoid double slashing' do
        get :script_with_url, url: '/url.js'
        does(last_response).match?  '<script src="/assets/url.js" type="text/javascript"></script>'
      end
    end

    Testing :style_tag do

      get :style_with_url, 'url.css'
      does(last_response).match? '<link href="/assets/url.css" rel="stylesheet">'

      get :style_with_src, 'src.css'
      does(last_response).match? '<link href="src.css" rel="stylesheet">'

      get :style_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) =~ /some="param"/
      check(lines[0]) =~ /type="text\/css"/
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</style>'

      get :style_with_suffix, 'url.css', '-aloha'
      does(last_response).match? '<link href="url.css-aloha" rel="stylesheet">'

      Should 'avoid double slashing' do
        get :style_with_url, url: '/url.css'
        does(last_response).match? '<link href="/assets/url.css" rel="stylesheet">'
      end
    end

  end

  class TagHelpers < E

    def js
      js_tag params[:asset]
    end

    def js_with_suffix suffix
      js_tag params[:asset], suffix: suffix
    end

    def css
      css_tag params[:asset]
    end

    def css_with_suffix suffix
      css_tag params[:asset], suffix: suffix
    end

    def png
      png_tag params[:asset]
    end

    def png_with_suffix suffix
      png_tag params[:asset], suffix: suffix
    end
  end

  Spec.new self do
    eapp = E.new do
      assets_url '/assets'
      mount TagHelpers
    end
    app eapp
    map TagHelpers.base_url

    get :js, :asset => :master
    does(/src="\/assets\/master\.js"/).match_body?

    get :js_with_suffix, '-sfx', :asset => :master
    does(/src="\/assets\/master\.js\-sfx"/).match_body?

    get :css, :asset => :master
    does(/href="\/assets\/master\.css"/).match_body?

    get :css_with_suffix, '-sfx', :asset => :master
    does(/href="\/assets\/master\.css\-sfx"/).match_body?

    get :png, :asset => :master
    does(/src="\/assets\/master\.png"/).match_body?

    get :png_with_suffix, '-sfx', :asset => :master
    does(/src="\/assets\/master\.png\-sfx"/).match_body?
  end

  class SprocketsApp < E
    map :app

    def finder
      if asset = assets[params[:asset]]
        asset.pathname
      end
    end
  end

  Spec.new self do
    
    path1 = File.expand_path('../sprockets', __FILE__)
    path2 = File.expand_path('../assets', __FILE__)

    eapp = E.new do
      assets_url '/assets'
      assets.append_path path1
      assets.append_path path2
      mount SprocketsApp
    end
    app eapp

    Testing :server do
      map :assets

      get 'master.js'
      is(last_response).ok?
      does(/master\.js/).match_body?

      get 'app.js'
      is(last_response).ok?
      does(/AppClass/).match_body?
      does(/UIClass/).match_body?

      get 'app.css'
      is(last_response).ok?
      does(/body/).match_body?
      does(/div/).match_body?
    end

    Testing :finder do
      map :app

      get :finder, :asset => 'app.js'
      expect(File.dirname(last_response.body)) == path1
      
      get :finder, :asset => 'master.js'
      expect(File.dirname(last_response.body)) == path2
    end
  end

  Spec.new self do
    eapp = E.new do
      root File.expand_path('..', __FILE__)
      assets_url '/assets'
      assets.append_path 'assets'
    end
    app eapp
    map :assets

    Testing 'append_path with relative paths' do
      get 'master.js'
      is(last_response).ok?
      does(/master\.js/).match_body?

      get 'master.css'
      is(last_response).ok?
      does(/master\.css/).match_body?
    end
  end

  class AssetsMapper < E

    def get_assets_mapper type
      html = ''
      mapper = assets_mapper params[:baseurl]
      if src = params[:src]
        html << mapper.send(type, :src => src)
      else
        html << mapper.send(type, params[:url])
      end
      html
    end

    def assets_mapper_chdir type
      html = ''
      mapper = assets_mapper params[:baseurl]
      params[:scenario].each do |scenario|
        path, file = scenario.split
        if file.nil?
          file = path
          path = nil
        end
        mapper.cd path
        html << mapper.send(type, file)
      end
      html
    end

    def assets_mapper_with_block type
      html, url = '', params[:url]
      assets_mapper params[:baseurl] do
        html << send(type, url)
      end
      html
    end

    def assets_mapper_with_suffix type, suffix
      html, url = '', params[:url]
      assets_mapper params[:baseurl] do
        html << send(type, url, suffix: suffix)
      end
      html
    end
  end

  Spec.new AssetsMapper do

    def match? response, str
      check(response.respond_to?(:body) ? response.body : response) =~
        (str.is_a?(Regexp) ? str : Regexp.new(Regexp.escape str))
    end

    Testing :js do
      get :assets_mapper, :js_tag, :baseurl => './', :url => 'master'
      does(last_response).match? 'src="./master.js"'
      
      get :assets_mapper, :js_tag, :baseurl => '/', :url => 'master'
      does(last_response).match? 'src="/master.js"'

      get :assets_mapper, :js_tag, :baseurl => 'http://some.cdn', :url => 'master'
      does(last_response).match? 'src="http://some.cdn/master.js"'

      Should 'skip baseurl' do
        get :assets_mapper, :js_tag, :src => 'master', :baseurl => 'skipit'
        does(last_response).match? 'src="master.js"'
      end
    end

    Testing :css do
      get :assets_mapper, :css_tag, :baseurl => './', :url => 'master'
      does(last_response).match? 'href="./master.css"'
      
      get :assets_mapper, :css_tag, :baseurl => '/', :url => 'master'
      does(last_response).match? 'href="/master.css"'

      get :assets_mapper, :css_tag, :baseurl => 'http://some.cdn', :url => 'master'
      does(last_response).match? 'href="http://some.cdn/master.css"'

      Should 'skip baseurl' do
        get :assets_mapper, :css_tag, :src => 'master', :baseurl => 'skipit'
        does(last_response).match? 'href="master.css"'
      end
    end

    Testing :png do
      get :assets_mapper, :png_tag, :baseurl => './', :url => 'master'
      does(last_response).match? 'src="./master.png"'
      
      get :assets_mapper, :png_tag, :baseurl => '/', :url => 'master'
      does(last_response).match? 'src="/master.png"'

      get :assets_mapper, :png_tag, :baseurl => 'http://some.cdn', :url => 'master'
      does(last_response).match? 'src="http://some.cdn/master.png"'

      Should 'skip baseurl' do
        get :assets_mapper, :png_tag, :src => 'master', :baseurl => 'skipit'
        does(last_response).match? 'src="master.png"'
      end
    end

    Testing :AssetsLoaderWithBlock do
      get :assets_mapper_with_block, :js_tag, :url => 'master'
      does(last_response).match? 'src="master.js"'
      
      get :assets_mapper_with_block, :css_tag, :url => 'master', :baseurl => '/'
      does(last_response).match? 'href="/master.css"'

      get :assets_mapper_with_block, :css_tag, :url => 'master', :baseurl => './'
      does(last_response).match? 'href="./master.css"'

      get :assets_mapper_with_block, :png_tag, :url => 'master', :baseurl => 'http://some.cdn'
      does(last_response).match? 'src="http://some.cdn/master.png"'
    end

    Testing :AssetsLoaderWithSuffix do
      get :assets_mapper_with_suffix, :js_tag, '-sfx', :url => 'master'
      does(last_response).match? 'src="master.js-sfx"'
      
      get :assets_mapper_with_suffix, :css_tag, '-sfx', :url => 'master', :baseurl => '/'
      does(last_response).match? 'href="/master.css-sfx"'

      get :assets_mapper_with_suffix, :png_tag, '-sfx', :url => 'master', :baseurl => 'http://some.cdn'
      does(last_response).match? 'src="http://some.cdn/master.png-sfx"'
    end

    Testing :AssetsLoaderChdir do
      Should 'avoid redundant path traversal' do
        get :assets_mapper_chdir, :js_tag, :scenario => [ '../../etc/passwd jquery' ]
        does(last_response).match? 'src="etc/passwd/jquery.js"'

        get :assets_mapper_chdir, :js_tag, :scenario => [ '../etc/passwd jquery' ]
        does(last_response).match? 'src="etc/passwd/jquery.js"'

        get :assets_mapper_chdir, :js_tag, :scenario => ['vendor/jquery jquery', '../../../../ master']
        does(last_response).match? 'src="master.js"'
      end

      Should 'cd to vendor/jquery and load jquery.js' do
        get :assets_mapper_chdir, :js_tag, :baseurl => '/assets', :scenario => ['vendor/jquery jquery', '.. master', '/ master']
        does(last_response).match? 'src="/assets/vendor/jquery/jquery.js"'
        
        Then 'cd to .. and load vendor/master.js' do
          does(last_response).match? 'src="/assets/vendor/master.js"'
        end
        
        Then 'cd to / and load master.js' do
          does(last_response).match? 'src="/assets/master.js"'
        end
      end

      Should 'cd to vendor/jquery and load vendor/jquery/jquery.js' do
        get :assets_mapper_chdir, :js_tag, :baseurl => '/assets', :scenario => ['vendor/jquery jquery', '../.. master', '/scripts master']
        does(last_response).match? 'src="/assets/vendor/jquery/jquery.js"'
        
        Then 'cd to ../.. and load master.js' do
          does(last_response).match? 'src="/assets/master.js"'
        end
        
        Then 'cd to /scripts and load master.js' do
          does(last_response).match? 'src="/assets/scripts/master.js"'
        end
      end

      Should 'cd to css/themes and load css/themes/black.css' do
        
        get :assets_mapper_chdir, :css_tag, :baseurl => '/assets', :scenario => ['css/themes black', ' master', '/css master']
        does(last_response).match? 'href="/assets/css/themes/black.css"'
        
        Then 'cd to root and load master.css' do
          does(last_response).match? 'href="/assets/master.css"'
        end
        
        Then 'cd to /css and load master.css' do
          does(last_response).match? 'href="/assets/css/master.css"'
        end
      end

      Should 'behave well with rooted baseurls' do
        Should 'cd to vendor/icons/16x16 and load vendor/icons/16x16/file.png' do

          get :assets_mapper_chdir, :png_tag, :baseurl => '/public', :scenario => ['vendor/icons/16x16 file', '../.. sprite', '/icons folder']
          does(last_response).match? 'src="/public/vendor/icons/16x16/file.png"'

          Then 'cd to ../.. and load vendor/sprite.png' do
            does(last_response).match? 'src="/public/vendor/sprite.png"'
          end

          Then 'cd to /icons and load folder.png' do
            does(last_response).match? 'src="/public/icons/folder.png"'
          end
        end
      end

      Should 'behave well with protocoled baseurls' do
        Should 'cd to icons/16x16 and load icons/16x16/file.png' do
          
          get :assets_mapper_chdir, :png_tag, :baseurl => 'http://some.cdn', :scenario => ['icons/16x16 file', '.. sprite', '/imgs img']
          does(last_response).match? 'src="http://some.cdn/icons/16x16/file.png"'
          
          Then 'cd to .. and load sprite.png' do
            does(last_response).match? 'src="http://some.cdn/icons/sprite.png"'
          end
          
          Then 'cd to /imgs and load img.png' do
            does(last_response).match? 'src="http://some.cdn/imgs/img.png"'
          end
        end
      end
    end
  end
end
