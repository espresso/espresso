module EspressoFrameworkUtils
  include EspressoFrameworkConstants

  PATH_MODIFIERS = [
      /\A\.\.\Z/,
      '../', '/../', '/..',
      '..%2F', '%2F..%2F', '%2F..',
      '..\\', '\\..\\', '\\..',
      '..%5C', '%5C..%5C', '%5C..',
  ].freeze

  # "fluffing" potentially hostile paths.
  # to avoid paths traversing, replacing the matches below with a slash:
  # ../
  # /../
  # /..
  # ..\
  # \..\
  # \..
  # ..%2F
  # %2F..%2F
  # %2F..
  # ..%5C
  # %5C..%5C
  # %5C..
  #
  # @note
  #   it will also remove duplicating slashes.
  #
  # @note slow method! use only at load time
  #
  # @param [String, Symbol] *chunks
  # @return [String]
  def normalize_path path
    path.gsub ::Regexp.union(/\\+/, /\/+/, *PATH_MODIFIERS), '/'
  end
  module_function :normalize_path

  # rootify_url('path') # => /path
  # rootify_url('///some-path/') # => /some-path
  # rootify_url('/some', '/path/') # => /some/path
  # rootify_url('some', 'another', 'path/') # => /some/another/path
  #
  # @note slow method! use only at loadtime
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
  def build_path path, *args
    args.compact!
    path = path.to_s.dup
    if args.any?
      # making sure there are a slash between path and args
      path << '/' unless path =~ /\/\Z/
      
      # if last arg is a Hash, turn it into query string.
      # it is important to pop args before joining  them.
      if args.last.is_a?(Hash) && (params = args.pop.delete_if {|k,v| v.nil?}).any?
        return path << args.join('/') << '?' << Rack::Utils.build_nested_query(params)
      end
      return path << args.join('/')
    end
    path
  end
  module_function :build_path

  def is_app? obj
    obj.respond_to?(:base_url)
  end
  module_function :is_app?

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

  # call it like activesupport method
  # convert constant names to underscored (file) names
  def underscore(str)
    str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end
  module_function :underscore


  # returns the class names without modules
  def demodulize(const)
    const.name.to_s.split('::').last
  end
  module_function :demodulize


  # instance_exec at runtime is expensive enough,
  # so compiling procs into methods at load time.
  def proc_to_method *chunks, &proc
    chunks += [self.to_s, proc.__id__]
    name = ('__e__%s__' % chunks.join('_').gsub(/[^\w|\d]/, '_')).to_sym
    define_method name, &proc
    private name
    name
  end

  def register_slim_engine!
    if Object.const_defined?(:Slim)
      VIEW__ENGINE_BY_EXT['.slim'] = Slim::Template
      VIEW__ENGINE_BY_SYM[:Slim]  = Slim::Template
      VIEW__EXT_BY_ENGINE[Slim::Template] = '.slim'.freeze
    end
    def __method__; end
  end

  def is_ruby19?
    RUBY_VERSION.to_f > 1.8
  end
end
