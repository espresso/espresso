class E
  e_attributes :env, :action, :action_arguments
  e_attributes :required_arguments, :required_request_method

  e_attribute :request
  alias rq request

  e_attribute :format
  alias format? format

  e_attribute :canonical
  alias canonical? canonical

  def response
    @__e__response ||= Rack::Response.new
  end
  alias rs response

  def params
    @__e__params ||= EspressoFrameworkUtils.indifferent_params(request.params)
  end

  def action_with_format
    @__e__action_with_format ||=
      (format ? action.to_s + format : action).freeze
  end

  def initialize action
    route_setup = self.class.route_setup[action]
    self.action = route_setup[:action]
    self.canonical = route_setup[:canonical]
    self.action_arguments = route_setup[:action_arguments]
    self.required_arguments = route_setup[:required_arguments]
    self.required_request_method = route_setup[:request_method]
  end

  def call env
    
    self.env = env
    self.request = EspressoFrameworkRequest.new(env)
    self.format  = env[ENV__ESPRESSO_FORMAT]
    
    e_response = catch :__e__catch__response__ do

      if required_request_method
        fail(STATUS__NOT_IMPLEMENTED) unless env[ENV__REQUEST_METHOD] == required_request_method
      end

      min, max = required_arguments
      given = action_params__array.size

      min && given < min &&
        fail(STATUS__NOT_FOUND, 'min params accepted: %s; params given: %s' % [min, given])

      max && given > max &&
        fail(STATUS__NOT_FOUND, 'max params accepted: %s; params given: %s' % [max, given])

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


  # Set or retrieve the response status code.
  def status(value=nil)
    response.status = value if value
    response.status
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
      env[ENV__ESPRESSO_PATH_INFO].to_s.split('/').reject { |s| s.empty? }
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

  # following methods are delegated to class
  def base_url
    self.class.base_url
  end
  alias baseurl base_url

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
  alias user? user

end
