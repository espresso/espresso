module EspressoUtils
  include EspressoConstants

  PATH_MODIFIERS = Regexp.union([
      /\\+/,
      /\/+/,
      /\A\.\.\Z/,
      '../', '/../', '/..',
      '..%2F', '%2F..%2F', '%2F..',
      '..\\', '\\..\\', '\\..',
      '..%5C', '%5C..%5C', '%5C..',
  ].map { |x| x.is_a?(String) ? Regexp.escape(x) : x })

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
    path.gsub PATH_MODIFIERS, '/'
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
    '/' << normalize_path(paths.compact.join('/')).gsub(/\A\/+|\/+\Z/, '')
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

  def route_to_regexp route
    /\A#{Regexp.escape(route).gsub('/', '/+')}(.*)/n
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

  def action_to_route action_name, path_rules = EspressoConstants::E__PATH_RULES
    action_name = action_name.to_s.dup
    path_rules.each_pair {|from, to| action_name = action_name.gsub(from, to)}
    action_name
  end
  module_function :action_to_route

  def canonical_to_route canonical, action_setup
    args = [canonical]
    args << action_setup[:action_path] unless action_setup[:action_name] == E__INDEX_ACTION
    rootify_url(*args).freeze
  end

  def deRESTify_action action
    action_name, request_method = action.to_s.dup, :*
    HTTP__REQUEST_METHODS.each do |m|
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

  # instance_exec at runtime is expensive enough,
  # so compiling procs into methods at load time.
  def proc_to_method *chunks, &proc
    chunks += [self.to_s, proc.__id__]
    name = ('__e__%s__' % chunks.join('_').gsub(/[^\w|\d]/, '_')).to_sym
    define_method name, &proc
    private name
    name
  end

end
