class << E

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

      actions = begin
        (self.public_instance_methods(false)) +
        (@__e__alias_actions    || {}).keys   +
        (@__e__imported_methods || [])
      end.uniq - (@__e__included_methods || [])
      
      if actions.empty?
        define_method :index do |*|
          'Get rid of this placeholder by defining %s#index' % self.class
        end
        actions << :index
      end
      actions
    end
  end

  private
  def generate_action_setup action
    action_name, request_method = EUtils.deRESTify_action(action)
    
    action_path = EUtils.action_to_route(action_name, path_rules).freeze
    path = EUtils.rootify_url(base_url, action_path).freeze

    action_arguments, required_arguments = action_parameters(action)

    formats = formats(action)
    {
              controller: self,
                  action: action,
             action_name: action_name,
             action_path: action_path,
        action_arguments: action_arguments,
      required_arguments: required_arguments,
                    path: path.freeze,
                 formats: Hash[formats.zip(formats)].freeze, # Hash lookup is a lot faster than Array include
          request_method: request_method,
    }.freeze
  end

  # returning required parameters calculated by arity
  def action_parameters action
    method = self.instance_method(action)
    [method.parameters.freeze, EUtils.method_arity(method).freeze]
  end
end
