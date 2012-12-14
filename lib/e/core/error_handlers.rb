class << E

  # define callbacks to be executed on HTTP errors.
  #
  # @example handle 404 errors:
  #    class App < E
  #
  #      error 404 do |error_message|
  #        "Some weird error occurred: #{ error_message }"
  #      end
  #    end
  # @param [Integer] code
  # @param [Proc] proc
  def error code, &proc
    error! code, :keep_existing, &proc
  end

  def error! code, keep_existing = nil, &proc
    return if locked?
    error? code
    raise('please provide a proc to be executed on errors') unless proc
    method = proc_to_method :http, :error_procs, code, &proc
    setup__actions.each do |a|
      next if @error_handlers[code][a] && keep_existing
      @error_handlers[code][a] = [method, instance_method(method).arity]
    end
  end

  def error? code, action = nil
    (@error_handlers ||= {})[code] ||= {}
    @error_handlers[code][action] || @error_handlers[code][:*]
  end
end

class E
  # same as `halt` except it uses for body the proc defined by `error` at class level
  #
  # @example
  #    class App < E
  #
  #      # defining the proc to be executed on 404 errors
  #      error 404 do |message|
  #        render_view('layouts/404'){ message }
  #      end
  #
  #      get :index do |id, status|
  #        item = Model.fisrt id: id, status: status
  #        unless item
  #          # interrupt execution and send 404 error to browser.
  #          error 404, 'Can not find item by given ID and Status'
  #        end
  #        # if no item found, code here will not be executed
  #      end
  #    end
  def error status, body = nil
    (handler = self.class.error?(status)) &&
      (body = handler.last > 0 ? self.send(handler.first, body) : self.send(handler.first))
    halt status.to_i, body
  end
end
