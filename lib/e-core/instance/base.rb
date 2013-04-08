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
    @__e__response ||= EResponse.new
  end
  alias rs response

  def params
    @__e__params ||= EUtils.indifferent_params(request.params)
  end

  def action
    action_setup[:action]
  end

  def action_setup= setup
    @__e__action_setup = setup
  end
  def action_setup
    @__e__action_setup
  end

  def setup_action! action = nil
    if action ||= @__e__action_passed_at_initialize || env[EConstants::ENV__ESPRESSO_ACTION]
      if setup = self.class.action_setup[action]
        self.action_setup = setup[env[EConstants::ENV__REQUEST_METHOD]] || setup[:*]
        self.action_setup ||
          fail(EConstants::STATUS__NOT_IMPLEMENTED, "Resource found
            but it can be accessed only through %s" % setup.keys.join(", "))
      end
    end
    self.action_setup ||
      fail(EConstants::STATUS__NOT_FOUND, '%s %s not found' % [rq.request_method, rq.path])
  end
  private :setup_action!

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
    @__e__request = ERequest.new(env)
    @__e__format  = env[EConstants::ENV__ESPRESSO_FORMAT]

    e_response = catch :__e__catch__response__ do
      
      setup_action! unless action_setup

      min, max = action_setup[:required_arguments]
      given = action_params__array.size

      min && given < min &&
        fail(EConstants::STATUS__NOT_FOUND, 'min params accepted: %s; params given: %s' % [min, given])

      max && given > max &&
        fail(EConstants::STATUS__NOT_FOUND, 'max params accepted: %s; params given: %s' % [max, given])

      call!
    end
    e_response.body = [] if request.head?
    e_response.finish
  end

  def call!
    call_setups! :a

    # automatically set Content-Type by given format, if any.
    # @note this will override Content-Type set via setups.
    #       to override Content-Type set by format,
    #       use #content_type inside action
    format && content_type(format)

    response.body = nil
    body = self.send(action, *action_params__array)
    response.body ||= [body.to_s]

    call_setups! :z

    response[EConstants::HEADER__CONTENT_TYPE] ||= EConstants::CONTENT_TYPE__DEFAULT

    response
  rescue => e
    # if a error handler defined, use it
    if handler = error_handler_defined?(500)
      meth, arity = handler
      halt EConstants::STATUS__SERVER_ERROR, arity > 0 ? self.send(meth, e) : self.send(meth)
    else
      # otherwise raise rescued exception
      raise e
    end
  end
  private :call!

  def call_setups! position = :a
    setups(position).each {|m| self.send m}
  end

  def action_params__array
    @__e__action_params__array ||=
      (env[EConstants::ENV__ESPRESSO_PATH_INFO] || 
        env[EConstants::ENV__PATH_INFO]).to_s.split('/').reject(&:empty?).freeze
  end

  # @example
  #   def index id, status
  #     action_params
  #   end
  #   # GET /100/active
  #   # => {:id => '100', :status => 'active'}
  #
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
    @__e__action_params = EUtils.indifferent_params(action_params).freeze
  end

  # following methods are delegated to class
  %w[
    default_route
    base_url
    app
    canonicals
    path_rules
    middleware
  ].each do |meth|
    define_method meth do
      # somehow sometimes __method__ is nil in this context
      # TODO: find out how/why
      self.class.send meth
    end
  end
  alias baseurl base_url

  def setups position
    self.class.setups position, action, format
  end

  def formats
    self.class.formats action
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


  def user
    env[EConstants::ENV__REMOTE_USER]
  end
  alias user? user
end
