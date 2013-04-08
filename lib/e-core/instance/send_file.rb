class E
  
  # Serving static files.
  # Note that this blocks app while file readed/transmitted(on WEBrick and Thin, as minimum).
  # To avoid app locking, setup your Nginx/Lighttpd server to set proper X-Sendfile header
  # and use Rack::Sendfile middleware in your app.
  #
  # @param [String] path full path to file
  # @param [Hash] opts
  # @option opts [String] filename the name of file displayed in browser's save dialog
  # @option opts [String] content_type custom content_type
  # @option opts [String] last_modified
  # @option opts [String] cache_control
  # @option opts [Boolean] attachment if set to true, browser will prompt user to save file
  def send_file path, opts = {}

    file = ::Rack::File.new nil
    file.path = path
    (cache_control = opts[:cache_control]) && (file.cache_control = cache_control)
    response = file.serving env

    response[1][EConstants::HEADER__CONTENT_DISPOSITION] = opts[:attachment] ?
        'attachment; filename="%s"' % (opts[:filename] || ::File.basename(path)) :
        'inline'

    (content_type = opts[:content_type]) &&
      (response[1][EConstants::HEADER__CONTENT_TYPE] = content_type)

    (last_modified = opts[:last_modified]) &&
      (response[1][EConstants::HEADER__LAST_MODIFIED] = last_modified)

    halt response
  end

  # serve static files at dir path
  def send_files dir
    halt ::Rack::Directory.new(dir).call(env)
  end

  # same as `send_file` except it instruct browser to display save dialog
  def attachment path, opts = {}
    halt send_file path, opts.merge(:attachment => true)
  end
end
