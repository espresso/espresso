module EHelpersTest__Assets

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

    def get_assets_loader type
      loader = assets_loader params[:baseurl]
      if src = params[:src]
        loader.send(type, :src => src)
      else
        loader.send(type, params[:url])
      end
    end

    def assets_loader_chdir type
      loader = assets_loader params[:baseurl]
      params[:scenario].each do |scenario|
        path, file = scenario.split
        if file.nil?
          file = path
          path = nil
        end
        loader.cd path
        loader.send(type, file)
      end
      loader
    end

    def assets_loader_with_block type
      assets_loader params[:baseurl] do
        send type, params[:url]
      end
    end

    def assets_loader_with_multiple_urls type
      loader = assets_loader params[:baseurl]
      loader.send(type, *params[:urls] << (params[:opts] || {}))
      loader
    end

    def assets_loader_returning_an_array type
      loader = assets_loader params[:baseurl]
      loader.send(type, *params[:urls])
      ([''] + loader.to_a).join(params[:glue])
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

    Testing :AssetsLoader do
      Testing :js do
        Should 'use assets_url' do
          get :assets_loader, :js, :url => 'master'
          does(last_response).match? 'src="/assets/master.js"'
        end

        Should 'skip assets_url' do
          get :assets_loader, :js, :baseurl => './', :url => 'master'
          does(last_response).match? 'src="./master.js"'
          
          get :assets_loader, :js, :baseurl => '/', :url => 'master'
          does(last_response).match? 'src="/master.js"'

          get :assets_loader, :js, :baseurl => 'http://some.cdn', :url => 'master'
          does(last_response).match? 'src="http://some.cdn/master.js"'
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :js, :src => 'master', :baseurl => 'skipit'
          does(last_response).match? 'src="master.js"'
        end
      end

      Testing :css do
        Should 'use assets_url' do
          get :assets_loader, :css, :url => 'master'
          does(last_response).match? 'href="/assets/master.css"'
        end

        Should 'skip assets_url' do
          get :assets_loader, :css, :baseurl => './', :url => 'master'
          does(last_response).match? 'href="./master.css"'
          
          get :assets_loader, :css, :baseurl => '/', :url => 'master'
          does(last_response).match? 'href="/master.css"'

          get :assets_loader, :css, :baseurl => 'http://some.cdn', :url => 'master'
          does(last_response).match? 'href="http://some.cdn/master.css"'
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :css, :src => 'master', :baseurl => 'skipit'
          does(last_response).match? 'href="master.css"'
        end
      end

      Testing :png do
        Should 'use assets_url' do
          get :assets_loader, :png, :url => 'master'
          does(last_response).match? 'src="/assets/master.png"'
        end

        Should 'skip assets_url' do
          get :assets_loader, :png, :baseurl => './', :url => 'master'
          does(last_response).match? 'src="./master.png"'
          
          get :assets_loader, :png, :baseurl => '/', :url => 'master'
          does(last_response).match? 'src="/master.png"'

          get :assets_loader, :png, :baseurl => 'http://some.cdn', :url => 'master'
          does(last_response).match? 'src="http://some.cdn/master.png"'
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :png, :src => 'master', :baseurl => 'skipit'
          does(last_response).match? 'src="master.png"'
        end
      end
    end

    Testing :AssetsLoaderWithBlock do
      get :assets_loader_with_block, :js, :url => 'master'
      does(last_response).match? 'src="/assets/master.js"'
      
      get :assets_loader_with_block, :css, :url => 'master', :baseurl => '/'
      does(last_response).match? 'href="/master.css"'

      get :assets_loader_with_block, :css, :url => 'master', :baseurl => './'
      does(last_response).match? 'href="./master.css"'

      get :assets_loader_with_block, :png, :url => 'master', :baseurl => 'http://some.cdn'
      does(last_response).match? 'src="http://some.cdn/master.png"'
    end

    Testing :AssetsLoaderChdir do
      Should 'use baseurl when redundant backdirs provided' do
        get :assets_loader_chdir, :js, :scenario => [ '../../etc/passwd jquery' ]
        does(last_response).match? 'src="/assets/etc/passwd/jquery.js"'

        get :assets_loader_chdir, :js, :scenario => [ '../etc/passwd jquery' ]
        does(last_response).match? 'src="/assets/etc/passwd/jquery.js"'

        get :assets_loader_chdir, :js, :scenario => ['vendor/jquery jquery', '../../../../ master']
        does(last_response).match? 'src="/assets/master.js"'
      end

      Should 'cd to vendor/jquery and load vendor/jquery/jquery.js' do
        get :assets_loader_chdir, :js, :scenario => ['vendor/jquery jquery', '.. master', '/ master']
        does(last_response).match? 'src="/assets/vendor/jquery/jquery.js"'
        Then 'cd to .. and load vendor/master.js' do
          does(last_response).match? 'src="/assets/vendor/master.js"'
        end
        Then 'cd to / and load master.js' do
          does(last_response).match? 'src="/assets/master.js"'
        end
      end

      Should 'cd to vendor/jquery and load vendor/jquery/jquery.js' do
        get :assets_loader_chdir, :js, :scenario => ['vendor/jquery jquery', '../.. master', '/scripts master']
        does(last_response).match? 'src="/assets/vendor/jquery/jquery.js"'
        Then 'cd to ../.. and load master.js' do
          does(last_response).match? 'src="/assets/master.js"'
        end
        Then 'cd to /scripts and load master.js' do
          does(last_response).match? 'src="/assets/scripts/master.js"'
        end
      end

      Should 'cd to css/themes and load css/themes/black.css' do
        get :assets_loader_chdir, :css, :scenario => ['css/themes black', ' master', '/css master']
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
          get :assets_loader_chdir, :png, :baseurl => '/public', :scenario => ['vendor/icons/16x16 file', '../.. sprite', '/icons folder']
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
          get :assets_loader_chdir, :png, :baseurl => 'http://some.cdn', :scenario => ['icons/16x16 file', '.. sprite', '/imgs img']
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

    Testing :assets_loader_with_multiple_urls do

      urls = ['boot', 'setup', 'load']

      Testing :js do
        Should 'work well without opts' do
          get :assets_loader_with_multiple_urls, :js, :baseurl => '/static', :urls => urls
          urls.each do |url|
            does(last_response).match? 'src="/static/%s.js"' % url
          end
        end
        Should 'apply given opts to all tags' do
          get :assets_loader_with_multiple_urls, :js, :urls => urls, :opts => {:charset => 'UTF-8'}
          urls.each do |url|
            does(last_response).match? /src="\/assets\/#{Regexp.escape url}\.js([^\n]*)charset="UTF\-8"/m
          end
        end
      end

      Testing :css do
        Should 'work well without opts' do
          get :assets_loader_with_multiple_urls, :css, :baseurl => './', :urls => urls
          urls.each do |url|
            does(last_response).match? 'href="./%s.css"' % url
          end
        end
        Should 'apply given opts to all tags' do
          get :assets_loader_with_multiple_urls, :css, :urls => urls, :opts => {:charset => 'UTF-8'}
          urls.each do |url|
            does(last_response).match? /href="\/assets\/#{Regexp.escape url}\.css"([^\n]*)charset="UTF\-8"/
          end
        end
      end

      Testing :img do
        Should 'work well without opts' do
          get :assets_loader_with_multiple_urls, :png, :baseurl => 'http://blah.cdn', :urls => urls
          urls.each do |url|
            does(last_response).match? 'src="http://blah.cdn/%s.png"' % url
          end
        end
        Should 'apply given opts to all tags' do
          get :assets_loader_with_multiple_urls, :jpg, :urls => urls, :opts => {:alt => 'blah'}
          urls.each do |url|
            does(last_response).match? 'src="/assets/%s.jpg" alt="blah"' % url
          end
        end
      end

    end

    Testing :assets_loader_returning_an_array do
      urls, glue = ['boot', 'setup', 'load'], '|||'

      get :assets_loader_returning_an_array, :js, :urls => urls, :glue => glue
      urls.each do |url|
        does(last_response).match? '%s<script src="/assets/%s.js"' % [glue, url]
      end

      get :assets_loader_returning_an_array, :css, :urls => urls, :glue => glue
      urls.each do |url|
        does(last_response).match? '%s<link href="/assets/%s.css"' % [glue, url]
      end

      get :assets_loader_returning_an_array, :png, :urls => urls, :glue => glue
      urls.each do |url|
        does(last_response).match? '%s<img src="/assets/%s.png"' % [glue, url]
      end

      get :assets_loader_returning_an_array, :jpg, :urls => urls, :glue => glue
      urls.each do |url|
        does(last_response).match? '%s<img src="/assets/%s.jpg"' % [glue, url]
      end
    end

  end

  Spec.new self do
    eapp = EApp.new do
      assets_url :assets, true
      assets_fullpath ::File.expand_path('../assets', __FILE__)
      mount App
    end
    app eapp
    map :assets

    get 'master.js'
    check(last_response.status) == 200
    expect(last_response["Content-Type"]) == "application/javascript"
    expect(last_response.body) == 'master.js'

    get 'master.css'
    check(last_response.status) == 200
    expect(last_response["Content-Type"]) == "text/css"
    expect(last_response.body) == 'master.css'

    get 'master.png'
    check(last_response.status) == 200
    expect(last_response["Content-Type"]) == "image/png"
  end

end
