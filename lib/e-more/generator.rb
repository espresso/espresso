require 'yaml'
require 'logger'

class EspressoGenerator

  include EspressoConstants
  include EspressoUtils

  INDENTATION = (" " * 2).freeze

  attr_reader :dst_root, :boot_file
  attr_accessor :logger

  def initialize dst_root, logger = nil
    src_root  = File.expand_path('../../../app', __FILE__) + '/'
    @src_base = (src_root + 'base/').freeze
    @src_gemfiles = (src_root + 'Gemfiles/').freeze

    @dst_root  = (dst_root + '/').freeze
    @boot_file = (@dst_root + 'app/boot.rb').freeze
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
      :root   => root,
      :app    => File.join(root, 'app/'),
      :config => File.join(root, 'config/')
    }
    [:controllers, :models, :views].each do |u|
      paths[u] = File.join(paths[:app], u.to_s, '')
    end
    unit = paths[args.first] ? args.shift : nil
    unit ? File.join(paths[unit], *args) : paths
  end

  def in_app_folder?
    File.exists?(dst_path[:controllers]) ||
      fail("Current folder does not seem to contain a Espresso application")
  end

  private

  def generate_project name, orm = nil

    name.nil? || name.empty? && fail("Please provide project name via second argument")
    name =~ /\.\.|\// && fail("Project name can not contain slashes nor ..")

    project_path = dst_path(:append => name)
    File.exists?(project_path[:root]) && fail("#{name} already exists")

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

    insert_orm(orm, project_path) if orm
  end

  def generate_controller name, route = nil

    name.nil? || name.empty? && fail("Please provide controller name via second argument")
    before, ctrl_name, after = namespace_to_source_code(name)

    source_code, i = [], INDENTATION * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name} < E"
    if route
      source_code << "#{i + INDENTATION}map '#{route}'"
      source_code << INDENTATION
    end

    ["def index", INDENTATION, "end"].each do |line|
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
    o
    File.open(file, 'w') {|f| f << source_code}
  end

  def generate_route ctrl_name, name, *args

    action_file, action = valid_action?(ctrl_name, name)

    File.exists?(action_file) && fail("#{name} action/route already exists")

    before, ctrl_name, after = namespace_to_source_code(ctrl_name)

    source_code, i = [], '  ' * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name}"

    args = args.any? ? ' ' + args.map {|a| a.sub(/\,\Z/, '')}.join(', ') : ''
    source_code << (i + INDENTATION + "def #{action + args}")
    action_source_code = [INDENTATION]
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
    File.exists?(action_file) ||
      fail("#{name} action/route does not exists. Please create it first")

    _, ctrl = valid_controller?(ctrl_name)

    App.boot!
    ctrl_instance = ctrl.new
    ctrl_instance.respond_to?(action.to_sym) ||
      fail("#{unrootify action_file} exists but #{action} action not defined.
        Please define it manually or delete #{unrootify action_file} and start over.")
    
    action_name, request_method = deRESTify_action(action)
    ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
    ctrl_instance.call_setups!
    path = File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?)

    o
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
    
    orm ||= Cfg.db[:orm]

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
    path.sub(regexp, '')
  end

  def insert_orm orm, project_path
    orm_gem = if orm =~ /\Aa/i
      'activerecord'
    elsif orm =~ /\Ad/i
      'data_mapper'
    elsif orm =~ /\As/i
      'sequel'
    end
    if orm_gem
      file = project_path[:config] + 'database.yml'
      cfg = YAML.load(File.read(file))
      %w[dev prod test].each do |env|
        env_cfg = cfg[env] || cfg[env.to_sym]
        env_cfg.update 'orm' => orm_gem
      end

      o
      o "Updating #{unrootify file}"
      o "+ orm: #{orm_gem}"
      o
      File.open(file, 'w') {|f| f << YAML.dump(cfg)}

      gems = File.readlines(@src_gemfiles + orm_gem)
      file = project_path[:root] + 'Gemfile'
      o "Updating #{unrootify file}"
      gems.each {|g| o "+ #{g}"}
      o
      File.open(file, 'a') do |f|
        f << "\n"
        gems.each {|g| f << g}
      end
    else
      o "Unknown ORM #{orm}"
    end
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

  def fail msg
    o msg
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

  def namespace_to_source_code name
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
end
