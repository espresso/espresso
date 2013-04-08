class E
  
  # same as `halt(error_code)` except it carrying previous defined error handlers.
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
  #          # interrupt execution and send 404 error to browser.
  #          fail 404, 'Can not find item by given ID and Status'
  #        end
  #        # code here will be executed only if item found
  #      end
  #    end
  #
  def fail error_code = EConstants::STATUS__SERVER_ERROR, body = nil
    if handler = error_handler_defined?(error_code)
      meth, arity = handler
      body = arity > 0 ? self.send(meth, body) : [self.send(meth), body].join
    end
    halt error_code.to_i, body
  end
  alias fail!  fail
  alias quit   fail
  alias quit!  fail
  alias error  fail
  alias error! fail

  def error_handler_defined? error_code
    self.class.error_handler(error_code) || self.class.error_handler(:*)
  end

end
