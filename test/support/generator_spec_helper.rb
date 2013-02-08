module GeneratorSpecHelper
  
  def cleanup
    FileUtils.rm_rf GENERATOR__DST_ROOT + 'App'
  end
end
