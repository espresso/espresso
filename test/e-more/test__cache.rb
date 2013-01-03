module EMoreTest__Cache

  class App < E

    before do
      if key = params[:__clear_cache__]
        key == '*' ? clear_cache! : clear_cache!(key)
      end
    end

    def index

    end

    def heavy_io
      cache do
        content
      end
    end

    def heavy_render
      banners = cache :banners do
        params[:banners] || content
      end
      items = cache :items do
        params[:items] || content
      end
      [banners, items].join '/'
    end

    def clear_cache_by_regexp
      updated = false
      if key = params[:key]
        clear_cache! /#{key}/
      end
      cache :clear_cache_by_regexp do
        updated = true
      end
      updated
    end

    private
    def content
      ::Digest::MD5.hexdigest rand(1024**1024).to_s
    end

  end

  Spec.new App do

    io = get :heavy_io
    expect(io.status) == 200

    a, b = [], []
    10.times do
      get :heavy_io
      a << io.body
      b << last_response.body
    end
    expect(a) == b

    render = get :heavy_render
    expect(render.status) == 200

    a, b = [], []
    10.times do
      get :heavy_render
      a << render.body
      b << last_response.body
    end
    expect(a) == b

    Should 'clear ALL cache' do
      get :index, :__clear_cache__ => '*'

      get :heavy_io
      refute(last_response.body) == io.body

      get :heavy_render
      refute(last_response.body) == render.body
    end

    Should 'clear cache by exact match keys' do

      banners, items = 2.times.map { rand.to_s }
      Should 'clear and store new cache' do
        get :__clear_cache__ => '*'

        render = get :heavy_render, :banners => banners, :items => items
        expect(render.body) == [banners, items].join('/')

        a, b = [], []
        10.times do
          get :heavy_render, :banners => rand.to_s, :items => rand.to_s
          a << render.body
          b << last_response.body
        end
        expect(a) == b
      end

      new_banners, new_items = 2.times.map { rand.to_s }
      Context 'updating banners' do
        get :__clear_cache__ => :banners

        get :heavy_render, :banners => new_banners, :items => rand.to_s
        expect(last_response.body) == [new_banners, items].join('/')
      end

      Context 'updating items' do
        get :__clear_cache__ => :items

        get :heavy_render, :banners => rand.to_s, :items => new_items
        expect(last_response.body) == [new_banners, new_items].join('/')
      end
    end

    Should 'clear by given regexp' do

      get :clear_cache_by_regexp
      expect(last_response.body) == 'true'

      get :clear_cache_by_regexp
      expect(last_response.body) == 'false'

      %w[
        clear
        cache
        by
        regexp
        clear_cache
        clear_cache_by
        clear_cache_by_regexp
      ].each do |key|
        get :clear_cache_by_regexp, :key => key
        expect(last_response.body) == 'true'
      end
      
      %w[foo bar baz].each do |key|
        get :clear_cache_by_regexp, :key => key
        expect(last_response.body) == 'false'
      end

    end

  end
end
