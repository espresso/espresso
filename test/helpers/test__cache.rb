module EHelpersTest__Cache

  class App < E

    before do
      if key = params[:__clear_cache__]
        key == '*' ? clear_cache! : clear_cache!(key.to_sym)
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

    def clear_cache_like_array
      updated = false
      if keys = params[:keys]
        clear_cache_like! keys
      end
      cache ['clear' ,'cache' ,'like' ,'array'] do
        updated = true
      end
      updated
    end

    def clear_cache_like_regexp
      updated = false
      if key = params[:key]
        clear_cache_like! /#{key}/
      end
      cache 'clear_cache_like_regexp' do
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
      r = get :heavy_io
      a << io.body
      b << r.body
    end
    expect(a) == b

    render = get :heavy_render
    expect(render.status) == 200

    a, b = [], []
    10.times do
      r = get :heavy_render
      a << render.body
      b << r.body
    end
    expect(a) == b

    Should 'clear cache' do
      get :index, :__clear_cache__ => '*'

      r = get :heavy_io
      expect(r.status) == 200
      refute(r.body) == io.body

      r = get :heavy_render
      expect(r.status) == 200
      refute(r.body) == render.body
    end

    Should 'update selectively' do

      banners, items = 2.times.map { rand.to_s }
      Should 'clearing and setting cache' do
        get :__clear_cache__ => '*'

        render = get :heavy_render, :banners => banners, :items => items
        expect(render.status) == 200
        expect(render.body) == [banners, items].join('/')

        a, b = [], []
        10.times do
          r = get :heavy_render, :banners => rand.to_s, :items => rand.to_s
          a << render.body
          b << r.body
        end
        expect(a) == b
      end

      new_banners, new_items = 2.times.map { rand.to_s }
      Context 'updating banners' do
        get :__clear_cache__ => :banners

        r = get :heavy_render, :banners => new_banners, :items => rand.to_s
        expect(r.body) == [new_banners, items].join('/')
      end

      Context 'updating items' do
        get :__clear_cache__ => :items

        r = get :heavy_render, :banners => rand.to_s, :items => new_items
        expect(r.body) == [new_banners, new_items].join('/')
      end
    end

    Should 'clear by given array' do
      get :clear_cache_like_array
      expect(last_response.body) == 'true'
      
      get :clear_cache_like_array
      expect(last_response.body) == 'false'

      [
        ['clear' ],
        ['clear' ,'cache'],
        ['clear' ,'cache' ,'like' ],
        ['clear' ,'cache' ,'like' ,'array'],
      ].each do |keys|
        get :clear_cache_like_array, :keys => keys
        expect(last_response.body) == 'true'
      end

      [
        ['clear', 'blah'],
        ['clear' ,'cache' ,'like', 'blah'],
        ['clear' ,'cache' ,'like' ,'array', 'yo'],
      ].each do |keys|
        get :clear_cache_like_array, :keys => keys
        expect(last_response.body) == 'false'
      end
    end

    Should 'clear by given regexp' do

      get :clear_cache_like_regexp
      expect(last_response.body) == 'true'

      get :clear_cache_like_regexp
      expect(last_response.body) == 'false'

      [
        'clear',
        'cache',
        'like',
        'regexp',
        'clear_cache',
        'clear_cache_like',
        'clear_cache_like_regexp',
      ].each do |key|
        get :clear_cache_like_regexp, :key => key
        expect(last_response.body) == 'true'
      end
      
      [
        'cache_clear',
        'like_clear_cache',
        'regexp_like_clear_cache',
      ].each do |key|
        get :clear_cache_like_regexp, :key => key
        expect(last_response.body) == 'false'
      end

    end

  end
end


