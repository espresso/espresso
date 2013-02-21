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
    @__e__response ||= EspressoResponse.new
  end
  alias rs response

  def params
    @__e__params ||= EspressoUtils.indifferent_params(request.params)
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
    if action ||= @__e__action_passed_at_initialize || env[ENV__ESPRESSO_ACTION]
      if setup = self.class.action_setup[action]
        self.action_setup = setup[env[ENV__REQUEST_METHOD]] || setup[:*]
        self.action_setup ||
          fail(STATUS__NOT_IMPLEMENTED, "Resource found
            but it can be accessed only through %s" % setup.keys.join(", "))
      end
    end
    self.action_setup ||
      fail(STATUS__NOT_FOUND, '%s %s not found' % [rq.request_method, rq.path])
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
    @__e__request = EspressoRequest.new(env)
    @__e__format  = env[ENV__ESPRESSO_FORMAT]

    e_response = catch :__e__catch__response__ do
      
      setup_action! unless action_setup

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

  def call_setups! position = :a
    setups(position).each {|m| self.send m}
  end

  def action_params__array
    @__e__action_params__array ||=
      (env[ENV__ESPRESSO_PATH_INFO] || 
        env[ENV__PATH_INFO]).to_s.split('/').reject(&:empty?).freeze
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
    @__e__action_params = EspressoUtils.indifferent_params(action_params).freeze
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
    env[ENV__REMOTE_USER]
  end
  alias user? user

  # The response object. See Rack::Response and Rack::ResponseHelpers for
  # more info:
  # http://rack.rubyforge.org/doc/classes/Rack/Response.html
  # http://rack.rubyforge.org/doc/classes/Rack/Response/Helpers.html
  class EspressoResponse < Rack::Response # kindly borrowed from Sinatra
    def initialize(*)
      super
      headers['Content-Type'] ||= 'text/html'
    end

    def body=(value)
      value = value.body while Rack::Response === value
      @body = String === value ? [value.to_str] : value
    end

    def each
      block_given? ? super : enum_for(:each)
    end

    def finish
      result = body

      if drop_content_info?
        headers.delete "Content-Length"
        headers.delete "Content-Type"
      end

      if drop_body?
        close
        result = []
      end

      if calculate_content_length?
        # if some other code has already set Content-Length, don't muck with it
        # currently, this would be the static file-handler
        headers["Content-Length"] = body.inject(0) { |l, p| l + Rack::Utils.bytesize(p) }.to_s
      end

      [status.to_i, header, result]
    end

    private

    def calculate_content_length?
      headers["Content-Type"] and not headers["Content-Length"] and Array === body
    end

    def drop_content_info?
      status.to_i / 100 == 1 or drop_body?
    end

    def drop_body?
      [204, 205, 304].include?(status.to_i)
    end
  end
end
