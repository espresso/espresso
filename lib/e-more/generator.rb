class EspressoProjectGenerator

  include EspressoConstants
  include EspressoUtils

  INDENTATION = (" " * 2).freeze

  attr_reader :src_root, :dst_root, :boot_file

  def initialize dst_root
    @src_root = (File.expand_path('../../../app', __FILE__) + '/').freeze
    @dst_root = (dst_root + '/').freeze
    @boot_file = (@dst_root + 'app/boot.rb').freeze
  end

  def generate_project name, orm = nil

    name.nil? || name.empty? && fail("Please provide project name via second argument")
    name =~ /\.\.|\// && fail("Project name can not contain slashes nor ..")

    project_path = dst_path(name)
    File.exists?(project_path[:root]) && fail("#{name} already exists")

    o "Generating \"#{name}\" project...\n"

    folders, files = Dir[src_root + '**/*'].partition do |entry|
      File.directory?(entry)
    end

    FileUtils.mkdir(project_path[:root])
    o "  #{name}/"
    folders.each do |folder|
      path = unrootify(folder, src_root)
      o "  `- #{path}"
      FileUtils.mkdir(project_path[:root] + path)
    end

    files.reject {|f| File.basename(f) =~ /\AGemfile\./}.each do |file|
      path = unrootify(file, src_root)
      o "  Writing #{path}"
      FileUtils.cp(file, project_path[:root] + path)
    end

    insert_orm(orm, project_path) if orm
  end

  def insert_orm orm, project_path
    orm_class, orm_ext = if orm =~ /\Aa/i
      [:ActiveRecord, '.ar']
    elsif orm =~ /\Ad/i
      [:DataMapper, '.dm']
    elsif orm =~ /\As/i
      [:Sequel, '.sq']
    end
    if orm_class
      file = project_path[:config] + 'database.yml'
      cfg = YAML.load(File.read(file))
      %w[dev prod test].each do |env|
        env_cfg = cfg[env] || cfg[env.to_sym]
        env_cfg.update 'orm' => orm_class
      end

      o
      o "Updating #{unrootify file}"
      o "orm: :#{orm_class}"
      o
      File.open(file, 'w') {|f| f << YAML.dump(cfg)}

      gems = File.read(src_root  + 'Gemfile' + orm_ext)
      file = project_path[:root] + 'Gemfile'
      o "Updating #{unrootify file}"
      o gems
      o
      File.open(file, 'a') do |f|
        f << "\n"
        f << gems
      end
    else
      o "Unknown ORM #{orm}"
    end
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
    o "--- Generating #{name} controller ---"
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
    o "--- Generating #{name} route ---"
    o "Writing #{unrootify action_file}"
    o source_code
    File.open(action_file, 'w') {|f| f << source_code}
  end

  def generate_view ctrl_name, name

    action_file, action = valid_action?(ctrl_name, name)
    File.exists?(action_file) ||
      fail("#{name} action/route does not exists. Please create it first")

    _, ctrl = valid_controller?(ctrl_name)

    App.to_app!
    ctrl_instance = ctrl.new
    ctrl_instance.respond_to?(action.to_sym) ||
      fail("#{unrootify action_file} exists but #{action} action not defined.
        Please define it manually or delete #{unrootify action_file} and start over.")
    
    action_name, request_method = deRESTify_action(action)
    ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
    ctrl_instance.call_setups!
    path = File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?)

    o
    o "--- Generating #{name} view ---"
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
    o "--- Generating #{name} model ---"
    o "Creating #{unrootify path}/"
    FileUtils.mkdir(path)
    file = path + '.rb'
    o "Writing  #{unrootify file}"
    o source_code
    o
    File.open(file, 'w') {|f| f << source_code}
  end

  def in_app_folder?
    File.exists?(dst_path[:controllers]) ||
      fail("Current folder does not seem to contain a Espresso application")
  end

  private

  def unrootify path, root = dst_path[:root]
    path.sub(root, '')
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

  def dst_path path = '.'
    root = File.expand_path(path, dst_root) + '/'
    paths = {:root => root, :config => File.join(root, 'config/')}
    [:controllers, :models, :views].inject(paths) do |map,p|
      map.merge p => File.join(root, 'app', p.to_s, '')
    end
  end

  def fail msg
    puts msg
    exit 1
  end

  def o msg = ''
    puts msg
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
