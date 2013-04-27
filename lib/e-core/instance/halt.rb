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
  #
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

  # same as `halt` except it carrying earlier defined error handlers.
  # if no handler found it behaves exactly as `halt(error_code[, body])`.
  #
  # @example
  #    class App < E
  #
  #      # defining the proc to be executed on 404 errors
  #      error 404 do |message|
  #        render_layout('layouts/404') { message }
  #      end
  #
  #      def index id, status
  #        item = Model.fisrt(:id => id, :status => status)
  #        unless item
  #          # interrupt execution and send a styled 404 error to browser.
  #          styled_halt 404, 'Can not find item by given ID and Status'
  #        end
  #        # code to be executed only if item found
  #      end
  #    end
  #
  def styled_halt error_code = EConstants::STATUS__SERVER_ERROR, body = nil
    if handler = error_handler_defined?(error_code)
      meth, arity = handler
      body = arity > 0 ? self.send(meth, body) : [self.send(meth), body].join
    end
    halt error_code.to_i, body
  end
  alias styled_error  styled_halt
  alias styled_error! styled_halt
  alias fail   styled_halt
  alias fail!  styled_halt
  alias quit   styled_halt
  alias quit!  styled_halt
  alias error  styled_halt
  alias error! styled_halt

  def error_handler_defined? error_code
    self.class.error_handler(error_code) || self.class.error_handler(:*)
  end

end
