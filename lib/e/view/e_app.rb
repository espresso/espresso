class EApp
  # for most apps, most expensive operations are fs operations and template compilation.
  # to avoid these operations compiled templates are stored into memory
  # and just rendered on consequent requests.
  #
  # by default, compiled templates are kept in memory.
  #
  # if you want to use a different pool, set it by using `compiler_pool` at class level.
  # make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, `delete` and `clear` methods.
  # also, the pool SHOULD accept ARRAYS as keys.
  def compiler_pool pool = nil
    return @compiler_pool if @compiler_pool
    @compiler_pool = pool if pool
    @compiler_pool ||= Hash.new
  end
end

def compiler_cache key, &proc
  compiler_pool[key] ||= proc.call
end

# call `clear_compiler!` without args to update all compiled templates.
# to update only specific templates pass as arguments the IDs you used to enable compiler.
#
# @example
#    class App < E
#
#      def index
#        @banners = render_view :banners, '' => :banners
#        @ads = render_view :ads, '' => :ads
#        render '' => true
#      end
#
#      before do
#        if 'some condition occurred'
#          # updating only @banners and @ads
#          clear_compiler! :banners, :ads
#        end
#        if 'some another condition occurred'
#          # update all templates
#          clear_compiler!
#        end
#      end
#    end
#
# @note using of non-unique keys will lead to templates clashing
#
def clear_compiler! *keys
  clear_compiler *keys
  ipcm_trigger :clear_compiler, *keys
end

# same as clear_compiler! except it work only on current process
def clear_compiler *keys
  keys.size == 0 ?
    compiler_pool.clear :
    keys.each do |key|
      compiler_pool.keys.each { |k| k.first == key && compiler_pool.delete(k) }
    end
end

# clear compiler of keys that matching given regexp(s) or array(s).
# if regexp given it will match only String and Symbol keys.
# if array given it will match only Array keys.
def clear_compiler_like! *keys
  clear_compiler_like *keys
  ipcm_trigger :clear_compiler_like, *keys
end

def clear_compiler_like *keys
  keys.each do |key|
    if key.is_a? Array
      compiler_pool.keys.each do |k|
        ekey = k.first
        ekey.is_a?(Array) &&
          ekey.size >= key.size &&
          ekey.slice(0, key.size) == key &&
          compiler_pool.delete(k)
      end
    elsif key.is_a? Regexp
      compiler_pool.keys.each do |k|
        ekey = k.first
        (
          (ekey.is_a?(String) && ekey =~ key) ||
          (ekey.is_a?(Symbol) && ekey.to_s =~ key)
        ) && compiler_pool.delete(k)
      end
    else
      raise "#%s only accepts arrays and regexps" % __method__
    end
  end
end
