require 'yaml'
require 'logger'

class EspressoGenerator

  include EspressoUtils

  INDENTATION = (" " * 2).freeze
  # classes which underscored name does not result in gem name
  CLASS_TO_GEM = {
    :RDiscount => 'rdiscount',
    :BlueCloth => 'bluecloth',
    :RedCloth  => 'redcloth',
    :WikiCloth => 'wikicloth',
    :RDoc      => 'rdoc',
  }

  attr_reader :dst_root, :boot_file
  attr_accessor :logger

  def initialize dst_root, logger = nil
    src_root  = File.expand_path('../../../app', __FILE__) + '/'
    @src_base = (src_root + 'base/').freeze
    @src_gemfiles = (src_root + 'Gemfiles/').freeze

    @dst_root  = (dst_root  + '/').freeze
    @boot_file = (@dst_root + 'base/boot.rb').freeze
    @logger    = logger || logger == false ? logger : Logger.new(STDOUT)
  end

  def generate unit, *args
    catch :exception_catching_symbol do
      self.send "generate_%s" % unit, *args
      true
    end
  end

  def dst_path *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    root = dst_root + opts[:append].to_s + '/'
    paths = {
      :root => root,
      :base => File.join(root, 'base/'),
      :config => File.join(root, 'config/')
    }
    [:controllers, :models, :views].each do |u|
      paths[u] = File.join(paths[:base], u.to_s, '')
    end
    unit = paths[args.first] ? args.shift : nil
    unit ? File.join(paths[unit], *args) : paths
  end

  def in_app_folder?
    File.exists?(dst_path[:controllers]) ||
      fail("Current folder does not seem to contain a Espresso application")
  end

  def parse_input *input
    catch :exception_catching_symbol do
      args, setups, string_setups = [], {}, []
      input.flatten.each do |a|
        case
        when a =~ /\Ao:/i, a =~ /\Am:/i
          orm = extract_setup(a)
          if valid_orm = valid_orm?(orm)
            setups[:orm] = valid_orm
            string_setups << a
          else
            o 'WARN: invalid ORM provided - "%s"' % orm
            o 'Supported ORMs: activerecord, data_mapper, sequel'
            fail
          end
        when a =~ /\Ae:\w+/i
          engine = extract_setup(a).to_s.to_sym
          if valid_engine?(engine)
            setups[:engine] = engine
            string_setups << a
          else
            o 'WARN: invalid engine provided - "%s"' % engine
            o 'Supported engines(Case Sensitive): %s' % VIEW__ENGINE_BY_SYM.keys.join(', ')
            fail
          end
        when a =~ /\Af:/
          if format = extract_setup(a)
            setups[:format] = format
            string_setups << a
          end
        else
          args << a
        end
      end
      [args, setups, string_setups.join(' ')]
    end
  end

  private

  def extract_setup input
    input.scan(/:(.+)/).flatten.last
  end

  def generate_project name, setups = {}

    name.nil? || name.empty? && fail("Please provide project name via second argument")
    name =~ /\.\.|\// && fail("Project name can not contain slashes nor ..")

    project_path = dst_path(:append => name)
    File.exists?(project_path[:root]) && fail("#{name} already exists")

    o
    o '--- Generating "%s" project ---' % name

    folders, files = Dir[@src_base + '**/*'].partition do |entry|
      File.directory?(entry)
    end

    FileUtils.mkdir(project_path[:root])
    o "  #{name}/"
    folders.each do |folder|
      path = unrootify(folder, @src_base)
      o "  `- #{path}"
      FileUtils.mkdir(project_path[:root] + path)
    end

    files.each do |file|
      path = unrootify(file, @src_base)
      o "  Writing #{path}"
      FileUtils.cp(file, project_path[:root] + path)
    end

    update_config  setups, project_path
    update_gemfile setups, project_path
  end

  def generate_controller name, route = nil, setups = {}
    route.is_a?(Hash) && (setups = route) && (route = nil)

    name.nil? || name.empty? && fail("Please provide controller name via second argument")
    before, ctrl_name, after = namespace_to_source_code(name)

    source_code, i = [], INDENTATION * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name} < E"
    if route
      source_code << "#{i + INDENTATION}map '#{route}'"
    end
    if engine = setups[:engine]
      source_code << "#{i + INDENTATION}engine :#{engine}"
    end
    if format = setups[:format]
      source_code << "#{i + INDENTATION}format '#{format}'"
    end
    source_code << INDENTATION

    ["def index", INDENTATION + "render", "end"].each do |line|
      source_code << (i + INDENTATION + line.to_s)
    end

    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    
    path = dst_path[:controllers] + class_name_to_route(name)
    File.exists?(path) && fail("#{name} controller already exists")
    o
    o '--- Generating "%s" controller ---' % name
    o "Creating #{unrootify path}/"
    FileUtils.mkdir(path)
    file = path + '.rb'
    o "Writing  #{unrootify file}"
    o source_code
    File.open(file, 'w') {|f| f << source_code}
  end

  def generate_route ctrl_name, name, *args

    action_file, action = valid_action?(ctrl_name, name)

    File.exists?(action_file) && fail("#{name} action/route already exists")

    before, ctrl_name, after = namespace_to_source_code(ctrl_name, false)

    source_code, i = [], '  ' * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name}"

    args = args.any? ? ' ' + args.map {|a| a.sub(/\,\Z/, '')}.join(', ') : ''
    source_code << (i + INDENTATION + "def #{action + args}")
    action_source_code = ["render"]
    if block_given?
      action_source_code = yield
      action_source_code.is_a?(Array) || action_source_code = [action_source_code]
    end
    action_source_code.each do |line|
      source_code << (i + INDENTATION*2 + line.to_s)
    end
    source_code << (i + INDENTATION + "end")

    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    o
    o '--- Generating "%s" route ---' % name
    o "Writing #{unrootify action_file}"
    o source_code
    File.open(action_file, 'w') {|f| f << source_code}
  end

  def generate_view ctrl_name, name

    action_file, action = valid_action?(ctrl_name, name)

    _, ctrl = valid_controller?(ctrl_name)

    App.boot!
    ctrl_instance = ctrl.new
    ctrl_instance.respond_to?(action.to_sym) ||
      fail("#{action} action does not exists. Please create it first")
    
    action_name, request_method = deRESTify_action(action)
    ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
    ctrl_instance.call_setups!
    path = File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?)

    o '--- Generating "%s" view ---' % name
    if File.exists?(path)
      File.directory?(path) ||
        fail("#{unrootify path} should be a directory")
    else
      o "Creating #{unrootify path}/"
      FileUtils.mkdir(path)
    end
    file = File.join(path, action + ctrl_instance.engine_ext?)
    o "Touching #{unrootify file}"
    o
    FileUtils.touch file
  end

  def generate_model name, orm = nil

    name.nil? || name.empty? && fail("Please provide model name via second argument")
    before, model_name, after = namespace_to_source_code(name)
    
    orm ||= Cfg[:orm]

    superclass = ''
    orm && orm =~ /\Aa/i && superclass = ' < ActiveRecord::Base'
    orm && orm =~ /\As/i && superclass = ' < Sequel::Model'

    insertions = []
    if orm && orm =~ /\Ad/i
      insertions << 'include DataMapper::Resource'
      insertions << INDENTATION
      insertions <<'property :id, Serial'
    end
    insertions << INDENTATION

    source_code, i = [], INDENTATION * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{model_name + superclass}"

    insertions.each do |line|
      source_code << (i + INDENTATION + line.to_s)
    end

    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    
    path = dst_path[:models] + class_name_to_route(name)
    File.exists?(path) && fail("#{name} model already exists")
    
    o
    o '--- Generating "%s" model ---' % name
    o "Creating #{unrootify path}/"
    FileUtils.mkdir(path)
    file = path + '.rb'
    o "Writing  #{unrootify file}"
    o source_code
    o
    File.open(file, 'w') {|f| f << source_code}
  end

  def unrootify path, root = nil
    root = (root || dst_path[:root]).gsub(/\/+/, '/')
    regexp = /\A#{Regexp.escape(root)}/
    path.gsub(/\/+/, '/').sub(regexp, '')
  end

  def update_config data, project_path
    return if data.empty?

    file = project_path[:config] + 'config.yml'
    cfg  = YAML.load(File.read(file))
    E__ENVIRONMENTS.each do |env|
      env_cfg = cfg[env] || cfg[env.to_s] || next
      env_cfg.update data
    end

    o
    o "Updating #{unrootify file}"
    o YAML.dump(data)
    o
    File.open(file, 'w') {|f| f << YAML.dump(cfg)}
  end

  def update_gemfile data, project_path
    return if data.empty?
    file = project_path[:root] + 'Gemfile'
    o "Updating #{unrootify file}"
    File.open(file, 'a') do |f|
      [data[:orm], data[:engine]].compact.each do |gem|
        gemfile = @src_gemfiles + gem.to_s
        if File.file?(gemfile)
          gems = File.readlines(gemfile)
        else
          gems = ["gem '%s'" % (CLASS_TO_GEM[gem] || underscore(gem.to_s))]
        end
        gems.each {|g| f << g; o "+ #{g}"}
      end
    end
  end

  def valid_orm? orm
    return unless orm.is_a?(String)
    case
    when orm =~ /\Aa/i
      'activerecord'
    when orm =~ /\Ad/i
      'data_mapper'
    when orm =~ /\As/i
      'sequel'
    end
  end

  def valid_engine? engine
    VIEW__ENGINE_BY_SYM.has_key? engine
  end

  def valid_controller? name
    name.nil? || name.empty? && fail("Please provide controller name")

    ctrl_path = dst_path[:controllers] + class_name_to_route(name) + '/'
    File.directory?(ctrl_path) ||
      fail("#{name} controller does not exists. Please create it first")

    ctrl = name.split('::').inject(Object) do |ns,c|
      ctrl_folder = unrootify(ctrl_path).sub(/\/+\Z/, '*')
      ns.const_defined?(c) || fail("#{ctrl_folder} exists but #{name} controller not defined.
        Please define it manually or delete #{ctrl_folder} and start over.")
      ns.const_get(c)
    end
    [ctrl_path, ctrl]
  end

  def valid_action? ctrl_name, name
    ctrl_path, ctrl = valid_controller?(ctrl_name)
    name.nil? || name.empty? && fail("Please provide action/route via second argument")
    path_rules = ctrl.path_rules.inject({}) do |map,(r,s)|
      map.merge /#{Regexp.escape s}/ => r.source
    end
    action = action_name_to_route(name, path_rules)
    validate_action_name(action)
    action_file = ctrl_path + action + '.rb'
    [action_file, action]
  end

  def fail msg = nil
    if msg
      o
      o '!!! %s !!!' % msg
      o
    end
    throw :exception_catching_symbol, false
  end

  def o msg = ''
    return unless @logger
    @logger << "%s\n" % msg
  end

  def validate_constant_name constant
    constant =~ /\W/      && fail("Wrong constant name - %s, it should contain only alphanumerics" % constant)
    constant =~ /\A[0-9]/ && fail("Wrong constant name - %s, it should start with a letter" % constant)
    constant =~ /\A[A-Z]/ || fail("Wrong constant name - %s, it should start with a uppercase letter" % constant)
    constant
  end

  def validate_action_name action
    action =~ /\W/ && fail("Action names may contain only alphanumerics")
    action
  end

  def namespace_to_source_code name, ensure_uninitialized = true
    ensure_uninitialized && constant_in_use?(name) && fail("#{name} constant already in use")
    
    namespace = name.split('::').map {|c| validate_constant_name c}
    ctrl_name = namespace.pop
    before, after = [], []
    namespace.each do |c|
      i = INDENTATION * before.size
      before << "#{i}module %s" % c
      after  << "#{i}end"
    end
    [before, ctrl_name, after.reverse << ""]
  end

  def constant_in_use? name
    namespace = name.split('::').map {|c| validate_constant_name c}
    namespace.inject(Object) do |o,c|
      o.const_defined?(c) ? o.const_get(c) : break
    end
  end
end
