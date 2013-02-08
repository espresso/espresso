class E

  # stop executing any code and send response to browser.
  #
  # accepts an arbitrary number of arguments.
  # if arg is an Integer, it will be used as status code.
  # if arg is a Hash, it is treated as headers.
  # if it is an array, it is treated as Rack response and are sent immediately, ignoring other args.
  # any other args are treated as body.
  #
  # @example returning "Well Done" body with 200 status code
  #    halt 'Well Done'
  #
  # @example halting quietly, with empty body and 200 status code
  #    halt
  #
  # @example returning error with 500 code:
  #    halt 500, 'Sorry, some fatal error occurred'
  #
  # @example custom content type
  #    halt File.read('/path/to/theme.css'), 'Content-Type' => mime_type('.css')
  #
  # @example sending custom Rack response
  #    halt [200, {'Content-Disposition' => "attachment; filename=some-file"}, some_IO_instance]
  #
  # @param [Array] *args
  def halt *args
    args.each do |a|
      case a
        when Fixnum
          response.status = a
        when Array
          status, headers, body = a
          response.status = status
          response.headers.update headers
          response.body = body
        when Hash
          response.headers.update a
        else
          response.body = [a.to_s]
      end
    end
    response.body ||= []
    throw :__e__catch__response__, response
  end

end
