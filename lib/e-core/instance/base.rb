class E

  def initialize action = nil
    @__e__action_passed_at_initialize = action
  end

  def env
    @__e__env
  end

  def request
    @__e__request
  end
  alias rq request

  def response
    @__e__response ||= Rack::Response.new
  end
  alias rs response

  def params
    @__e__params ||= EspressoFrameworkUtils.indifferent_params(request.params)
  end

  def action
    action_setup[:action]
  end

  def action_setup setup = nil
    @__e__action_setup = setup if setup
    @__e__action_setup
  end

  def action_name
    action_setup[:action_name]
  end

  def canonical
    action_setup[:canonical]
  end
  alias canonical? canonical

  def action_with_format
    @__e__action_with_format ||= (format ? action.to_s + format : action).freeze
  end

  def format
    @__e__format
  end
  
  def call env
    
    @__e__env     = env
    @__e__request = EspressoFrameworkRequest.new(env)
    @__e__format  = env[ENV__ESPRESSO_FORMAT]

    unless action_setup
      if action = @__e__action_passed_at_initialize || env[ENV__ESPRESSO_ACTION]
        action_setup self.class.action_setup(action, env[ENV__REQUEST_METHOD])
      end
      action_setup ||
        fail(STATUS__NOT_FOUND, '%s %s route not found or misconfigured' % [rq.request_method, rq.path])
    end
    
    e_response = catch :__e__catch__response__ do

      min, max = action_setup[:required_arguments]
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

    response[HEADER__CONTENT_TYPE] ||= CONTENT_TYPE__DEFAULT

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

  def action_params__array
    @__e__action_params__array ||=
      (env[ENV__ESPRESSO_PATH_INFO] || 
        env[ENV__PATH_INFO]).to_s.split('/').reject(&:empty?).freeze
  end

  if RESPOND_TO__PARAMETERS
    # @example ruby 1.9+
    #    def index id, status
    #      action_params
    #    end
    #    # /100/active
    #    #> {:id => '100', :status => 'active'}
    def action_params
      return @__e__action_params if @__e__action_params

      action_params, given_params = {}, Array.new(action_params__array) # faster than dup
      action_setup[:action_arguments].each_with_index do |type_name, index|
        type, name = type_name
        if type == :rest
          action_params[name] = []
          until given_params.size < (action_setup[:action_arguments].size - index)
            action_params[name] << given_params.shift
          end
        else
          action_params[name] = given_params.shift
        end
      end
      @__e__action_params = EspressoFrameworkUtils.indifferent_params(action_params).freeze
    end
  else
    # @example ruby 1.8
    #    def index id, status
    #      action_params
    #    end
    #    # /100/active
    #    #> ['100', 'active']
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

  def alias_actions
    self.class.alias_actions[action] || []
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
