class E
  def cache(*a, &b); app.cache(*a, &b); end
  def clear_cache!(*a); app.clear_cache!(*a); end
  def cache_pool; app.cache_pool; end
end

class EApp

  # very basic cache implementation.
  # by default the cache will be kept in memory.
  # if you want to use a different pool, 
  # set it by using `cache_pool` at app level.
  # make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, `keys`, `delete` and `clear`
  #
  def cache_pool pool = nil
    return @cache_pool if @cache_pool
    @cache_pool = pool if pool
    @cache_pool ||= Hash.new
  end

  # simply running a block and store returned value.
  # on next request the stored value will be returned.
  # 
  # @note
  #   value is not stored if block returns false or nil
  #
  if RUBY_VERSION.to_f >= 1.9
    def cache key = nil, &proc
      key = key ? (key.respond_to?(:join) ? key.join : key.to_s) : proc.source_location
      cache_pool[key] || ( (val = proc.call) && (cache_pool[key] = val) )
    end
  else # ruby1.8
    def cache key = nil, &proc
      key = key ? (key.respond_to?(:join) ? key.join : key.to_s) : proc.to_s.split('@').last
      cache_pool[key] || ( (val = proc.call) && (cache_pool[key] = val) )
    end
  end

  # a simple way to manage stored cache.
  # any number of arguments(actually matchers) accepted.
  # matchers can be of String, Symbol or Regexp type. any other arguments ignored
  # 
  # @example
  #    class App < E
  #
  #      before do
  #        if 'some condition occurred'
  #          # clearing cache only for @red_banners and @db_items
  #          clear_cache! :red_banners, :db_items
  #        end
  #        if 'some another condition occurred'
  #          # clearing all cache
  #          clear_cache!
  #        end
  #        if 'Yet another condition occurred'
  #          # clearing cache by regexp
  #          clear_cache! /banners/, /db/
  #        end
  #      end
  #    end
  #
  #    def index
  #      @db_items = cache :db_items do
  #        # ...
  #      end
  #      @red_banners = cache :red_banners do
  #        # ...
  #      end
  #      @blue_banners = cache :blue_banners do
  #        # ...
  #      end
  #      # ...
  #    end
  #
  #    def products
  #      cache do
  #        # fetch and render products
  #      end
  #    end
  #  end
  #
  # @param [Array] keys
  def clear_cache! *matchers
    clear_cache *matchers
    ipcm_trigger :clear_cache, *matchers
  end

  # same as `clear_cache!` except it is working only on current process
  #
  # @param [Array] keys
  def clear_cache *matchers
    return cache_pool.clear if matchers.empty?
    keys = Array.new(cache_pool.keys)
    matchers.each do |matcher|
      mkeys = matcher.is_a?(Regexp) ?
        keys.select {|k| k =~ matcher} :
        keys.select {|k| k == matcher}
      mkeys.each {|k| cache_pool.delete k}
    end
  end

end
