class E
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
end
