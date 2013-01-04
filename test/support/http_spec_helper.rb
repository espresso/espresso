module HttpSpecHelper
  def is_status?(status)
    is(last_response.status) == status
  end

  def protected?
    is_status? 401
  end

  def authorized?
    is_status? 200
  end

  def is_ok?
    is_status? 200
  end

  def is_not_found?
    is_status? 404
  end

  def is_redirect?(status=302)
    is_status?(status)
  end

  def is_charset?(charset)
    prove(last_response.header['Content-Type']) =~ %r[charset=#{Regexp.escape charset}]
  end

  def is_last_modified?(time)
    prove(last_response.headers['Last-Modified']) == time
  end

  def is_content_type?(type)
    if type[0] == '.' # extensions, lookup in mime types
      expect(last_response.header['Content-Type']) =~ %r[#{Rack::Mime::MIME_TYPES.fetch(type)}]
    else
      expect(last_response.header['Content-Type']) == type
    end
  end

  def is_header?(headertype, val)
    expect(last_response.headers[headertype]) == val
  end

  def is_body?(val)
    if val.is_a?(Regexp)
      expect(last_response.body) =~ val
    else
      expect(last_response.body) == val
    end
  end

  def is_ok_body?(val)
    is_ok?
    is_body?(val)
  end

  def is_location?(location)
    is?(last_response.headers['Location']) == location
  end
end