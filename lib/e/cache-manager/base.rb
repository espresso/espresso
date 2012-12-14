class E

  def cache *args, &proc
    app.send __method__, *args, &proc
  end

  def clear_cache! *args
    app.send __method__, *args
  end

  def clear_cache_like! *args
    app.send __method__, *args
  end
end
