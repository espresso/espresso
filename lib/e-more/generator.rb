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

  def generate_project name

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
      path = folder.sub(src_root, '')
      o "  `- #{path}"
      FileUtils.mkdir(project_path[:root] + path)
    end

    files.each do |file|
      path = file.sub(src_root, '')
      o "  Writing #{path}"
      FileUtils.cp(file, project_path[:root] + path)
    end
  end

  def generate_controller name, route = nil

    name.nil? || name.empty? && fail("Please provide controller name via second argument")
    before, ctrl_name, after = controller_source_code(name)

    source_code, i = [], INDENTATION * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name} < E"
    source_code << "#{i + INDENTATION}map '#{route}'" if route
    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    
    path = dst_path[:controllers] + class_name_to_route(name)
    File.exists?(path) && fail("%s controller already exists" % name)
    
    o
    o "--- Generating controller ---"
    o "Creating #{path.sub(dst_path[:root], '')}/"
    FileUtils.mkdir(path)
    file = path + '.rb'
    o "Writing  #{file.sub(dst_path[:root], '')}"
    o source_code
    o
    File.open(file, 'w') {|f| f << source_code}
  end

  def generate_route ctrl_name, name, *args

    action_file, action = valid_action?(ctrl_name, name)

    File.exists?(action_file) && fail("#{name} action/route already exists")

    before, ctrl_name, after = controller_source_code(ctrl_name)

    source_code, i = [], '  ' * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name}"

    source_code << (i + INDENTATION + "def #{action}")
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
    o "--- Generating route ---"
    o "Writing #{action_file.sub(dst_path[:root], '')}"
    o source_code
    File.open(action_file, 'w') {|f| f << source_code}
  end

  def generate_view ctrl_name, name

    action_file, action = valid_action?(ctrl_name, name)
    action_relfile = action_file.sub(dst_path[:root], '')

    File.exists?(action_file) ||
      fail("#{name} action/route does not exists. Please create it first")

    _, ctrl = valid_controller?(ctrl_name)

    ctrl_instance = ctrl.new
    ctrl_instance.respond_to?(action.to_sym) ||
      fail("#{action_relfile} exists but #{action} action not defined.
        Please define it manually or delete #{action_relfile} and start over.")
    
    action_name, request_method = deRESTify_action(action)
    ctrl_instance.action_setup  = ctrl.action_setup[action_name][request_method]
    ctrl_instance.call_setups!
    path = File.join(ctrl_instance.view_path?, ctrl_instance.view_prefix?)

    o
    o "--- Generating view ---"
    if File.exists?(path)
      File.directory?(path) || fail("#{path.sub(dst_path[:root], '')} should be a directory")
    else
      o "Creating #{path.sub(dst_path[:root], '')}"
      FileUtils.mkdir(path)
    end
    file = File.join(path, action + ctrl_instance.engine_ext?)
    o "Writing  #{file.sub(dst_path[:root], '')}"
    o
    FileUtils.touch file
  end

  def in_app_folder?
    File.exists?(dst_path[:controllers]) ||
      fail("Current folder does not seem to contain a Espresso application")
  end

  private

  def valid_controller? name
    name.nil? || name.empty? && fail("Please provide controller name")

    ctrl_path = dst_path[:controllers] + class_name_to_route(name) + '/'
    File.directory?(ctrl_path) ||
      fail("#{name} controller does not exists. Please create it first")

    ctrl = name.split('::').inject(Object) do |ns,c|
      ctrl_folder = ctrl_path.sub(dst_path[:root], '').sub(/\/+\Z/, '*')
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
    [:controllers, :models, :views].inject({:root => root}) do |map,p|
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

  def controller_source_code name
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
