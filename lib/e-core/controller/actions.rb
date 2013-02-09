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
    @__e__public_actions ||= begin

      actions = (
        (self.public_instance_methods(false)) +
        (@__e__alias_actions    || {}).keys   +
        (@__e__included_actions || [])
      ).uniq
      
      if actions.empty?
        define_method :index do |*|
          'Get rid of this placeholder by defining %s#index' % self.class
        end
        actions << :index
      end
      actions
    end
  end

  def generate_action_setup action
    action_name, request_method = deRESTify_action(action)
    
    action_path = apply_path_rules(action_name)
    path = rootify_url(base_url, action_path).freeze
    path = '' if path == '/'

    action_arguments, required_arguments = action_parameters(action)

    format_regexp = formats(action).any? ?
      /(?:\A(?:\/{0,})?#{action})?(#{formats(action).map {|f| Regexp.escape f}.join("|")})\Z/ : nil

    {
              :controller => self,
                  :action => action,
             :action_name => action_name,
             :action_path => action_path,
        :action_arguments => action_arguments,
      :required_arguments => required_arguments,
                    :path => path.freeze,
           :format_regexp => format_regexp,
          :request_method => request_method
    }.freeze
  end

  def apply_path_rules action_name
    return ''.freeze if action_name == E__INDEX_ACTION
    action_name_to_route(action_name, path_rules).freeze
  end

  # returning required parameters calculated by arity
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
    [parameters.freeze, [min, max].freeze]
  end
  
end
