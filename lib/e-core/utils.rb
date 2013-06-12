module EUtils
  
  # "fluffing" potentially hostile paths to avoid paths traversing.
  #
  # @note
  #   it will also remove duplicating slashes.
  #
  # @note TERRIBLE SLOW METHOD! use only at load time
  #
  # @param [String, Symbol] path
  # @return [String]
  #
  def normalize_path path
    path.gsub EConstants::PATH_MODIFIERS, '/'
  end
  module_function :normalize_path

  # rootify_url('path') # => /path
  # rootify_url('///some-path/') # => /some-path
  # rootify_url('/some', '/path/') # => /some/path
  # rootify_url('some', 'another', 'path/') # => /some/another/path
  #
  # @note slow method! use only at loadtime
  #
  def rootify_url *paths
    '/' << EUtils.normalize_path(paths.compact.join('/')).gsub(/\A\/+|\/+\Z/, '')
  end
  module_function :rootify_url

  # takes an arbitrary number of arguments and builds an HTTP path.
  # Hash arguments will transformed into HTTP params.
  # empty hash elements will be ignored.
  #
  # @example
  #    build_path :some, :page, and: :some_param
  #    #=> some/page?and=some_param
  #    build_path 'another', 'page', with: {'nested' => 'params'}
  #    #=> another/page?with[nested]=params
  #    build_path 'page', with: 'param-added', an_ignored_param: nil
  #    #=> page?with=param-added
  #
  # @param path
  # @param [Array] args
  # @return [String]
  #
  def build_path path, *args
    path = path.to_s
    args.compact!

    query_string = args.last.is_a?(Hash) && (h = args.pop.delete_if{|k,v| v.nil?}).any? ?
      '?' << ::Rack::Utils.build_nested_query(h) : ''

    args.size == 0 || path =~ /\/\Z/ || args.unshift('')
    path + args.join('/') << query_string
  end
  module_function :build_path

  def is_app? obj
    obj.respond_to?(:base_url)
  end
  module_function :is_app?

  def route_to_regexp route, opts = {}
    route = rootify_url(route)
    boundary_check = if route == '/' || opts[:skip_boundary_check]
      nil
    else
      (formats = opts[:formats]) && formats.any? ?
        '(\/|%s|\Z)' % formats.map {|f| Regexp.escape(f) + '\Z'}.join('|') :
        '(\/|\Z)'
    end
    /\A#{Regexp.escape(route).gsub('/', '/+')}#{boundary_check}(.*)/.freeze
  end
  module_function :route_to_regexp

  # Enable string or symbol key access to the nested params hash.
  def indifferent_params(object)
    case object
    when Hash
      new_hash = indifferent_hash
      object.each { |key, value| new_hash[key] = indifferent_params(value) }
      new_hash
    when Array
      object.map { |item| indifferent_params(item) }
    else
      object
    end
  end
  module_function :indifferent_params

  # Creates a Hash with indifferent access.
  def indifferent_hash
    Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
  end
  module_function :indifferent_hash

  def method_arity method
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
    [min, max]
  end
  module_function :method_arity

  # call it like activesupport method
  # convert constant names to underscored (file) names
  def underscore str
    str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end
  module_function :underscore

  # convert class name to URL.
  # basically this will convert
  # Foo to foo
  # FooBar to foo_bar
  # Foo::Bar to foo/bar
  #
  def class_to_route class_name
    '/' << class_name.to_s.split('::').map {|c| underscore(c)}.join('/')
  end
  module_function :class_to_route

  def action_to_route action_name, path_rules = EConstants::PATH_RULES
    action_name = action_name.to_s.dup
    path_rules.each_pair {|from, to| action_name = action_name.gsub(from, to)}
    action_name
  end
  module_function :action_to_route

  def canonical_to_route canonical, action_setup
    args = [canonical]
    args << action_setup[:action_path] unless action_setup[:action_name] == EConstants::INDEX_ACTION
    EUtils.rootify_url(*args).freeze
  end
  module_function :canonical_to_route

  def deRESTify_action action
    action_name, request_method = action.to_s.dup, :*
    EConstants::HTTP__REQUEST_METHODS.each do |m|
      regex = /\A#{m}_/i
      if action_name =~ regex
        request_method = m.freeze
        action_name = action_name.sub(regex, '')
        break
      end
    end
    [action_name.to_sym, request_method]
  end
  module_function :deRESTify_action

  # Encodes the given token and options into an Authorization header value.
  #
  # @param [String] token
  # @param [Hash] options - optional Hash of the options
  #
  def encode_token_auth_credentials(token = nil, options = {})
    token.is_a?(Hash) && (options = token) && (token = nil)
    token && options = {token: token}.merge(options)
    'Token %s' % options.map {|k,v| '%s=%s' % [k, v.to_s.inspect]}.join(', ')
  end
  module_function :encode_token_auth_credentials

  def extract_hosts opts
    hosts = opts[:host] || opts[:hosts]
    hosts = [hosts] unless hosts.is_a?(Array)
    Hash[hosts.compact.map {|h| [h.to_s.strip.downcase.gsub(/\A\w+\:\/\//, ''), true]}]
  end
  module_function :extract_hosts

end
