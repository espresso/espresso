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

  end

  Spec.new self do
    assets_url = '/assets'
    app = EApp.new do
      assets_url(assets_url)
    end.mount(App)
    app(app)
    map App.base_url


    Testing :image_tag do

      get :image_with_url, 'image.jpg'
      is(last_response.body) == '<img src="/assets/image.jpg" alt="image" />' << "\n"

      get :image_with_src, 'image.jpg'
      is(last_response.body) == '<img src="image.jpg" alt="image" />' << "\n"
    end

    Testing :script_tag do

      get :script_with_url, 'url.js'
      check(last_response.body) == '<script src="/assets/url.js" type="text/javascript"></script>' << "\n"

      get :script_with_src, 'src.js'
      check(last_response.body) == '<script src="src.js" type="text/javascript"></script>' << "\n"

      get :script_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) =~ /some="param"/
      check(lines[0]) =~ /type="text\/javascript"/
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</script>'
    end

    Testing :style_tag do

      get :style_with_url, 'url.css'
      check(last_response.body) == '<link href="/assets/url.css" rel="stylesheet" />' << "\n"

      get :style_with_src, 'src.css'
      check(last_response.body) == '<link href="src.css" rel="stylesheet" />' << "\n"

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
          expect(last_response.body) =~ /src="\/assets\/master\.js"/
        end

        Should 'skip assets_url' do
          get :assets_loader, :js, :baseurl => './', :url => 'master'
          expect(last_response.body) =~ /src="\.\/master\.js"/
          
          get :assets_loader, :js, :baseurl => '/', :url => 'master'
          expect(last_response.body) =~ /src="\/master\.js"/

          get :assets_loader, :js, :baseurl => 'http://some.cdn', :url => 'master'
          expect(last_response.body) =~ /src="http:\/\/some\.cdn\/master\.js"/
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :js, :src => 'master', :baseurl => 'skipit'
          expect(last_response.body) =~ /src="master\.js"/
        end
      end

      Testing :css do
        Should 'use assets_url' do
          get :assets_loader, :css, :url => 'master'
          expect(last_response.body) =~ /href="\/assets\/master\.css"/
        end

        Should 'skip assets_url' do
          get :assets_loader, :css, :baseurl => './', :url => 'master'
          expect(last_response.body) =~ /href="\.\/master\.css"/
          
          get :assets_loader, :css, :baseurl => '/', :url => 'master'
          expect(last_response.body) =~ /href="\/master\.css"/

          get :assets_loader, :css, :baseurl => 'http://some.cdn', :url => 'master'
          expect(last_response.body) =~ /href="http:\/\/some\.cdn\/master\.css"/
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :css, :src => 'master', :baseurl => 'skipit'
          expect(last_response.body) =~ /href="master\.css"/
        end
      end

      Testing :png do
        Should 'use assets_url' do
          get :assets_loader, :png, :url => 'master'
          expect(last_response.body) =~ /src="\/assets\/master\.png"/
        end

        Should 'skip assets_url' do
          get :assets_loader, :png, :baseurl => './', :url => 'master'
          expect(last_response.body) =~ /src="\.\/master\.png"/
          
          get :assets_loader, :png, :baseurl => '/', :url => 'master'
          expect(last_response.body) =~ /src="\/master\.png"/

          get :assets_loader, :png, :baseurl => 'http://some.cdn', :url => 'master'
          expect(last_response.body) =~ /src="http:\/\/some\.cdn\/master\.png"/
        end

        Should 'skip assets_url and given baseurl' do
          get :assets_loader, :png, :src => 'master', :baseurl => 'skipit'
          expect(last_response.body) =~ /src="master\.png"/
        end
      end
    end

  end
end
