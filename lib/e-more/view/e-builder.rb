class EBuilder
  
  # for most apps, most expensive operations are fs operations and template compilation.
  # to avoid these operations, templates are compiled and stored into memory.
  # on consequent requests they are just rendered.
  # 
  # by default, compiler are disabled.
  # to enable it, set compiler pool at app level.
  # 
  # @example
  #   class App < E
  #     # ...
  #   end
  #   app = E.new
  #   app.compiler_pool Hash.new # will store compiler cache into a hash
  #   app.run
  #
  # if you want to use a custom pool, make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, and `clear` methods.
  def compiler_pool  pool =  nil
    @compiler_pool = pool if pool
    @compiler_pool
  end

  # clearing compiler cache
  #
  def clear_compiler!
    clear_compiler
    ipcm_trigger :clear_compiler
  end

  # same as clear_compiler! except it work only on current process
  def clear_compiler *keys
    compiler_pool && compiler_pool.clear
  end

end
