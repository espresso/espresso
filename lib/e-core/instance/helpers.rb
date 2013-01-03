class E

  [:cache, :clear_cache!, :clear_cache_like!].each do |m|
    define_method m do |*args, &proc|
      app.send m, *args, &proc
    end
  end

  # shortcut for Rack::Mime::MIME_TYPES.fetch
  def mime_type type, fallback = nil
    Rack::Mime::MIME_TYPES.fetch type, fallback
  end

  def escape_html *args
    ::CGI.escapeHTML *args
  end

  def unescape_html *args
    ::CGI.unescapeHTML *args
  end

  def escape_element *args
    ::CGI.escapeElement *args
  end

  def unescape_element *args
    ::CGI.unescapeElement *args
  end

  begin # borrowed from [Sinatra Framework](https://github.com/sinatra/sinatra)
    
    # Sugar for redirect (example:  redirect back)
    def back
      request.referer
    end

    # whether or not the status is set to 1xx
    def informational?
      status.between? 100, 199
    end

    # whether or not the status is set to 2xx
    def success?
      status.between? 200, 299
    end

    # whether or not the status is set to 3xx
    def redirect?
      status.between? 300, 399
    end

    # whether or not the status is set to 4xx
    def client_error?
      status.between? 400, 499
    end

    # whether or not the status is set to 5xx
    def server_error?
      status.between? 500, 599
    end

    # whether or not the status is set to 404
    def not_found?
      status == 404
    end
  end

end
