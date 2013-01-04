class E
  e_attributes :env, :request, :action, :format, :canonical

  def call env
    @__e__env = env
    e_response = catch :__e__catch__response__ do

      script_name = env[ENV__SCRIPT_NAME]
      script_name = '/' if script_name.size == 0
      rest_map    = self.class.url_map[script_name] || {}

      @__e__format,
        @__e__canonical,
        @__e__action,
        @__e__action_arguments, required_arguments =
        (rest_map[env[ENV__REQUEST_METHOD]] || []).map { |e| e.freeze }

      @__e__request = EspressoFrameworkRequest.new(env)

      action || fail(STATUS__NOT_FOUND)

      min, max = required_arguments
      given    = action_params__array.size

      min && given < min &&
        fail(STATUS__NOT_FOUND, 'min params accepted: %s; params given: %s' % [min, given])

      max && given > max &&
        fail(STATUS__NOT_FOUND, 'max params accepted: %s; params given: %s' % [max, given])

      clean_format_from_last_param!
      call!
    end
    e_response.body = [] if request.head?
    e_response.finish
  end

  def call!
    setups(:a).each {|m| self.send m}

    # automatically set Content-Type by given format, if any.
    # @note this will override Content-Type set via setups.
    #       to override Content-Type set by format,
    #       use #content_type inside action
    format && content_type(format)

    response.body = nil
    body = self.send(action, *action_params__array)
    response.body ||= [body.to_s]

    setups(:z).each {|m| self.send m}

    response
  rescue => e
    # if a error handler defined, use it
    if handler = error_handler_defined?(500)
      meth, arity = handler
      halt STATUS__SERVER_ERROR, arity > 0 ? self.send(meth, e) : self.send(meth)
    else
      # otherwise raise rescued exception
      raise e
    end
  end
  private :call!

  # if action serve some formats and it accepts at least one argument,
  # the format will be attached to last argument rather than to action name.
  #
  # @example
  #   format '.json'
  #
  #   def foo
  #     # will serve /foo.json
  #     # SCRIPT_NAME => '/foo.json' and PATH_INFO => '/'
  #     # format is automatically set to .json(extracted from rest_map)
  #   end
  #
  #   def bar id
  #     # will serve /bar/something.json
  #     # SCRIPT_NAME => '/bar' and PATH_INFO => '/something.json'
  #     # format are NOT automatically set,
  #     # so extracting it from last argument
  #   end
  #
  #   def baz id = nil
  #     # on /baz.json
  #     # SCRIPT_NAME => '/baz.json' and PATH_INFO => '/'
  #     # so format are set automatically
  #     #
  #     # on /baz/something.json
  #     # SCRIPT_NAME => '/baz' and PATH_INFO => '/something.json'
  #     # format are NOT automatically set,
  #     # so extracting it from last argument
  #   end
  #
  # the second meaning of this method is
  # to remove extension from last param
  # so user get clean data
  # ex: /foo/bar.html => /foo/bar => ['foo', 'bar']
  #
  def clean_format_from_last_param!
    if action_params__array.any? && formats.any? && format.nil?
      last_param_ext = File.extname(action_params__array.last).presence
      if last_param_ext && formats.any?{ |f|  f == last_param_ext }
        #REVIEW why are we inserting the extension into the params array before the last element?
        # expect "[:read, nil, \"book.xml\"]" == "[:read, \".xml\", \"book\"]" ## output, if I don't call the method
        action_params__array[action_params__array.size - 1] = action_params__array.last.remove_extension
        @__e__format = last_param_ext
      end
    end
    # it is highly important to freeze path params
    action_params__array.freeze
  end
  private :clean_format_from_last_param!

  def response
    @__e__response ||= Rack::Response.new
  end

  def params
    @__e__params ||= EspressoFrameworkUtils.indifferent_params(request.params)
  end

  # Set or retrieve the response status code.
  def status(value=nil)
    response.status = value if value
    response.status
  end

  def base_url
    self.class.base_url
  end



  def action_with_format
    @__e__action_with_format ||=
      (format ? action.to_s + format : action).freeze
  end

  # @example ruby 1.8
  #    def index id, status
  #      action_params
  #    end
  #    # /100/active
  #    #> ['100', 'active']
  def action_params__array
    # do not freeze path params here.
    # they will be frozen by #call
    # after format extension removed from last param.
    @__e__action_params__array ||=
      env[ENV__PATH_INFO].to_s.split('/').reject { |s| s.empty? }
  end

  # @example ruby 1.9+
  #    def index id, status
  #      action_params
  #    end
  #    # /100/active
  #    #> {:id => '100', :status => 'active'}
  def action_params_ruby19
    return @__e__action_params if @__e__action_params

    action_params, given_params = {}, Array.new(action_params__array) # faster than dup
    @__e__action_arguments.each_with_index do |type_name, index|
      type, name = type_name
      if type == :rest
        action_params[name] = []
        until given_params.size < (@__e__action_arguments.size - index)
          action_params[name] << given_params.shift
        end
      else
        action_params[name] = given_params.shift
      end
    end
    @__e__action_params = EspressoFrameworkUtils.indifferent_params(action_params).freeze
  end

  if E.is_ruby19?
    alias action_params action_params_ruby19
  else
    alias action_params action_params__array
  end

  def setups position
    self.class.setups position, action, format
  end

  def app
    self.class.app
  end

  def formats
    self.class.formats action
  end

  def canonicals
    self.class.canonicals
  end

  def [] action
    self.class[action]
  end

  def route *args
    self.class.route *args
  end

  def action_aliases
    self.class.action_aliases[action] || []
  end

  def path_rules
    self.class.path_rules
  end

  def middleware
    self.class.middleware
  end

  def user
    env[ENV__REMOTE_USER]
  end

end