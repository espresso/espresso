class E

  # simply reload the page, using current GET params.
  # to use custom GET params, pass a hash as first argument.
  #
  # @param [Hash, nil] params
  def reload params = nil
    redirect request.path, params || request.GET
  end

  # stop any code execution and redirect right away with 302 status code.
  # path is built by passing given args to route
  def redirect *args
    delayed_redirect EConstants::STATUS__REDIRECT, *args
    halt
  end

  # same as #redirect except it redirects with 301 status code
  def permanent_redirect *args
    delayed_redirect EConstants::STATUS__PERMANENT_REDIRECT, *args
    halt
  end

  # ensure the browser will be redirected after code execution finished
  def delayed_redirect *args
    status = args.first.is_a?(Numeric) ? args.shift : EConstants::STATUS__REDIRECT
    app = EUtils.is_app?(args.first) ? args.shift : nil
    action = args.first.is_a?(Symbol) ? args.shift : nil
    if app && action
      target = app.route action, *args
    elsif app
      target = app.route *args
    elsif action
      target = route action, *args
    else
      target = EUtils.build_path *args
    end
    response.body = []
    response.redirect target, status
  end
  alias deferred_redirect delayed_redirect

end
