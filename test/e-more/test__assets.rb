module EMoreTest__Assets

  class App < E

    def image_with_url url
      image_tag url
    end

    def image_with_src src
      image_tag :src => src
    end

    def script_with_url url
      script_tag url
    end

    def script_with_src src
      script_tag :src => src
    end

    def script_with_block
      script_tag params do
        params.inspect
      end
    end

    def style_with_url url
      style_tag url
    end

    def style_with_src src
      style_tag :src => src
    end

    def style_with_block
      style_tag params do
        params.inspect
      end
    end

  end

  Spec.new self do
    assets_url = '/assets'
    app = EApp.new do
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
      does(last_response).match? '<img src="/assets/image.jpg" alt="image">'

      get :image_with_src, 'image.jpg'
      does(last_response).match? '<img src="image.jpg" alt="image">'
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
    end

  end

  class TagHelpers < E

    def js
      js_tag params[:asset]
    end

    def css
      css_tag params[:asset]
    end

    def png
      png_tag params[:asset]
    end
  end

  Spec.new self do
    eapp = EApp.new do
      assets_url '/assets'
      mount TagHelpers
    end
    app eapp
    map TagHelpers.base_url

    get :js, :asset => :master
    does(/src="\/assets\/master\.js"/).match_body?

    get :css, :asset => :master
    does(/href="\/assets\/master\.css"/).match_body?

    get :png, :asset => :master
    does(/src="\/assets\/master\.png"/).match_body?
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

    eapp = EApp.new do
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
    eapp = EApp.new do
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

end
