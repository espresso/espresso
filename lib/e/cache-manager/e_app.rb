class EApp

  # very basic cache implementation.
  # by default the cache will be kept in memory.
  # if you want to use a different pool, 
  # set it by using `cache_pool` at app level.
  # make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, `delete` and `clear`
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
  if ::AppetiteConstants::RESPOND_TO__SOURCE_LOCATION # ruby1.9
    def cache key = nil, &proc
      key ||= proc.source_location
      cache_pool[key] || ( (val = proc.call) && (cache_pool[key] = val) )
    end
  else # ruby1.8
    def cache key = nil, &proc
      key ||= proc.to_s.split('@').last
      cache_pool[key] || ( (val = proc.call) && (cache_pool[key] = val) )
    end
  end

  # a simple way to manage stored cache.
  #
  # @example
  #    class App < E
  #
  #      before do
  #        if 'some condition occurred'
  #          # clearing cache only for @banners and @db_items
  #          clear_cache! :banners, :db_items
  #        end
  #        if 'some another condition occurred'
  #          # clearing all cache
  #          clear_cache!
  #        end
  #      end
  #    end
  #
  #    def index
  #      @db_items = cache :db_items do
  #        # fetching items
  #      end
  #      @banners = cache :banners do
  #        # render banners partial
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
  def clear_cache! *keys
    clear_cache *keys
    ipcm_trigger :clear_cache, *keys
  end

  # same as `clear_cache!` except it is working only on current process
  def clear_cache *keys
    keys.size == 0 ?
      cache_pool.clear :
      keys.each { |key| cache_pool.delete key }
  end

  # clear cache that's matching given regexp(s) or array(s).
  # if regexp given it will match only String and Symbol keys.
  # if array given it will match only Array keys.
  #
  def clear_cache_like! *keys
    clear_cache_like *keys
    ipcm_trigger :clear_cache_like, *keys
  end

  # same as clear_cache_like! except it does not trigger Inter-Process Cache Manager,
  # so use it only on single-process apps.
  def clear_cache_like *keys
    keys.each do |key|
      if key.is_a? Array
        cache_pool.keys.each do |k|
          k.is_a?(Array) &&
            k.size >= key.size &&
            k.slice(0, key.size) == key &&
            cache_pool.delete(k)
        end
      elsif key.is_a? Regexp
        cache_pool.keys.each do |k|
          (
            (k.is_a?(String) && k =~ key) ||
            (k.is_a?(Symbol) && k.to_s =~ key) 
          ) && cache_pool.delete(k)
        end
      else
        raise "#%s only accepts arrays and regexps" % __method__
      end
    end
  end

  # Inter-Process Cache Manager
  def ipcm_trigger *args
    if pids_reader
      pids = pids_reader.call rescue nil
      if pids.is_a?(Array) 
        pids.map {|p| p.to_i}.reject {|p| p < 2 || p == Process.pid }.each do |pid|
          begin
            File.open('%s/%s.%s-%s' % [ipcm_tmpdir, pid, args.hash, Time.now.to_f], 'w') do |f|
              f << Marshal.dump(args)
            end
            Process.kill ipcm_signal, pid
          rescue => e
            warn "was unable to perform IPCM operation because of error: %s" % ::CGI.escapeHTML(e.message)
          end
        end
      else
        warn "pids_reader should return an array of pids. Exiting IPCM..."
      end
    end
  end

  def ipcm_tmpdir path = nil
    return @ipcm_tmpdir if @ipcm_tmpdir
    if path
      @ipcm_tmpdir = ((path =~ /\A\// ? path : root + path) + '/').freeze
    else
      @ipcm_tmpdir = (root + 'tmp/ipcm/').freeze
    end
    FileUtils.mkdir_p @ipcm_tmpdir
    @ipcm_tmpdir
  end

  def ipcm_signal signal = nil
    return @ipcm_signal if @ipcm_signal
    @ipcm_signal = signal.to_s if signal
    @ipcm_signal ||= 'ALRM'
  end

  def register_ipcm_signal
    Signal.trap ipcm_signal do
      Dir[ipcm_tmpdir + '%s.*' % Process.pid].each do |file|
        unless (setup = Marshal.restore(File.read(file)) rescue nil).is_a?(Array)
          warn "Was unable to process \"%s\" cache file, skipping cache cleaning" % file
        end
        File.unlink file
        meth = setup.shift
        [ :clear_cache,
          :clear_cache_like,
          :clear_compiler,
          :clear_compiler_like,
        ].include?(meth) && self.send(meth, *setup)
      end
    end
  end

  def pids_reader &proc
    return @pids_reader if @pids_reader
    if proc.is_a?(Proc)
      @pids_reader = proc
      register_ipcm_signal
    end
  end
  alias pids pids_reader

end
