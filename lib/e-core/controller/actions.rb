class << E

  private
  # methods to be translated into HTTP paths.
  # if controller has no methods, defining #index with some placeholder text.
  #
  # @example
  #    class News < E
  #      map '/news'
  #
  #      def index
  #        # ...
  #      end
  #      # will serve GET /news/index and GET /news
  #
  #      def post_index
  #        # ...
  #      end
  #      # will serve POST /news/index and POST /news
  #    end
  #
  # @example
  #    class Forum < E
  #      map '/forum'
  #
  #      def online_users
  #        # ...
  #      end
  #      # will serve GET /forum/online_users
  #
  #      def post_create_user
  #        # ...
  #      end
  #      # will serve POST /forum/create_user
  #    end
  #
  # HTTP path params passed to action as arguments.
  # if arguments does not meet requirements, HTTP 404 error returned.
  #
  # @example
  #    def foo arg1, arg2
  #    end
  #    # /foo/some-arg/some-another-arg        - OK
  #    # /foo/some-arg                         - 404 error
  #
  #    def foo arg, *args
  #    end
  #    # /foo/at-least-one-arg                 - OK
  #    # /foo/one/or/any/number/of/args        - OK
  #    # /foo                                  - 404 error
  #
  #    def foo arg1, arg2 = nil
  #    end
  #    # /foo/some-arg/                        - OK
  #    # /foo/some-arg/some-another-arg        - OK
  #    # /foo/some-arg/some/another-arg        - 404 error
  #    # /foo                                  - 404 error
  #
  #    def foo arg, *args, last
  #    end
  #    # /foo/at-least/two-args                - OK
  #    # /foo/two/or/more/args                 - OK
  #    # /foo/only-one-arg                     - 404 error
  #
  #    def foo *args
  #    end
  #    # /foo                                  - OK
  #    # /foo/any/number/of/args               - OK
  #
  #    def foo *args, arg
  #    end
  #    # /foo/at-least-one-arg                 - OK
  #    # /foo/one/or/more/args                 - OK
  #    # /foo                                  - 404 error
  #
  # @return [Array]
  def public_actions
    return @public_actions if @public_actions

    actions = ((self.public_instance_methods(false) - Object.methods) +
      (@action_aliases||{}).keys).map { |a| a.to_sym }
    
    if actions.empty?
      define_method :index do |*|
        'Get rid of this placeholder by defining %s#index' % self.class
      end
      actions << :index
    end

    @public_actions = actions
  end

  # returns the served request_method(s) and routes served by given action.
  #
  # each action can serve one or more routes.
  # if no verb given, the action will serve all request methods.
  # to define an action serving only POST request method, prepend post_ or POST_ to action name.
  # same for any other request method.
  #
  # @example
  #    def read
  #      # will respond to any request method
  #    end
  #
  #    def post_login
  #      # will respond only to POST request method
  #    end
  #
  # @return [Array]
  def action_routes action
    request_methods, route = HTTP__REQUEST_METHODS, action.to_s
    HTTP__REQUEST_METHODS.each do |m|
      regex = /\A#{m}_/i
      if route =~ regex
        request_methods = [m]
        route = route.sub regex, ''
        break
      end
    end

    route.empty? && raise(ArgumentError, 'Wrong action name "%s"' % action)

    path_rules.keys.each do |key|
      route = route.gsub(key.is_a?(Regexp) ? key : /#{key}/, path_rules[key])
    end

    pages, dirs = [], []
    path = rootify_url(base_url, route)
    pages << {nil => [path, nil]}
    dirs  << {nil => [rootify_url(base_url), path]} if route == E__INDEX_ROUTE

    ((@action_aliases||{})[action]||[]).each do |url|
      pages << {nil => [rootify_url(base_url, url), nil]}
    end

    canonicals.each do |c|
      canonical_path = rootify_url(c, route)
      pages << {nil => [canonical_path, path]}
      dirs  << {nil => [rootify_url(c), path]} if route == E__INDEX_ROUTE
    end
    
    # if the action serve some format(s), creating a route for each format.
    # eg. when :page action serve .json format,
    # it will be available by two URLs: /page and /page.json
    formats(action).each do |format|
      pages.each { |page| page[format] = page[nil].map {|p| p ? p + format : p}}
    end

    [request_methods, pages + dirs].freeze
  end

  def generate_routes!
    @routes, @route_by_action, @route_by_action_with_format = [], {}, {}
    public_actions.each do |action|
      route = action_to_route(action)
      
      @route_by_action[action] = route[:path]
      formats(action).each do |format|
        @route_by_action_with_format[action.to_s + format] = route[:path]
      end
      
      @routes << route
      
      canonicals.each do |c|
        @routes << route.merge(:path => rootify_url(c, route), :canonical => route).freeze
      end

      ((@action_aliases||{})[action]||[]).each do |url|
        @routes << route.merge(:path => rootify_url(base_url, url)).freeze
      end
    end
    @routes.freeze
  end

  def action_to_route action
    path, request_method = action.to_s, nil
    HTTP__REQUEST_METHODS.each do |m|
      regex = /\A#{m}_/i
      if action.to_s =~ regex
        request_method = m
        path = path.sub(regex, '')
        break
      end
    end
    
    path == E__INDEX_ROUTE ?  path = '' :
      path_rules.each_pair {|from, to| path = path.gsub(from, to)}
    path = rootify_url(base_url, path).freeze

    action_arguments, required_arguments = action_parameters(action)

    format_regexp = formats(action).any? ?
      /(#{formats(action).map {|f| Regexp.escape f}.join("|")})\Z/ : nil

    {
      :ctrl     => self,
      :action   => action,
      :action_arguments => action_arguments,
      :required_arguments => required_arguments,
      :path => path,
      :regexp => /\A#{Regexp.escape(path).gsub('/', '/+')}(.*)/n,
      :format_regexp => format_regexp,
      :request_method => request_method,
    }.freeze
  end

  if RESPOND_TO__PARAMETERS # ruby 1.9
    # returning required parameters calculated by arity,
    # and, if available, parameters list.
    def action_parameters action
      method = self.instance_method(action)

      parameters = method.parameters
      min, max = 0, parameters.size

      unlimited = false
      parameters.each_with_index do |param, i|

        increment = param.first == :req

        if (next_param = parameters.values_at(i+1).first)
          increment = true if next_param[0] == :req
        end

        if param.first == :rest
          increment = false
          unlimited = true
        end
        min += 1 if increment
      end
      max = nil if unlimited
      [parameters, [min, max]]
    end
  else # ruby 1.8
    def action_parameters action
      method = self.instance_method(action)
      min = max = (method.arity < 0 ? -method.arity - 1 : method.arity)
      [nil, [min, max]]
    end
  end
  
end
