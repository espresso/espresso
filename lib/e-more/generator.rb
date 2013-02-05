class EspressoProjectGenerator

  include EspressoConstants
  include EspressoUtils

  INDENTATION = (" " * 2).freeze

  attr_reader :src_root, :dst_root

  def initialize src_root, dst_root
    @src_root, @dst_root = src_root, dst_root
  end

  def generate_project name
    name.nil? || name.empty? && fail("Please provide project name via second argument")
    name =~ /\.\.|\// && fail("Project name can not contain slashes nor ..")

    project_path = dst_path(name)
    File.exists?(project_path[:root]) && fail("#{name} already exists")

    putm "Generating \"#{name}\" project...\n"

    folders, files = Dir[src_root + '**/*'].partition do |entry|
      File.directory?(entry)
    end

    FileUtils.mkdir(project_path[:root])
    putm "  #{name}/"
    folders.each do |folder|
      path = folder.sub(src_root, '')
      putm "  `- #{path}"
      FileUtils.mkdir(project_path[:root] + path)
    end

    files.each do |file|
      path = file.sub(src_root, '')
      putm "  Writing #{path}"
      FileUtils.cp(file, project_path[:root] + path)
    end
  end

  def generate_controller name, route = nil

    in_app_folder?
    project_path = dst_path

    name.nil? || name.empty? && fail("Please provide controller name via second argument")
    before, ctrl_name, after = controller_source_code(name)

    source_code, i = [], INDENTATION * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name} < E"
    source_code << "#{i + INDENTATION}map '#{route}'" if route
    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    
    path = project_path[:controllers] + class_name_to_route(name)
    File.exists?(path) && fail("%s controller already exists" % name)
    putm
    putm "Creating #{path.sub(project_path[:root], '')}/"
    FileUtils.mkdir(path)
    file = path + '.rb'
    putm "Writing  #{file.sub(project_path[:root], '')}"
    putm source_code
    putm
    File.open(file, 'w') {|f| f << source_code}
  end

  def generate_route ctrl_name, name, *args

    in_app_folder?
    project_path = dst_path
    
    ctrl_name.nil? || ctrl_name.empty? && fail("Please provide controller name")

    ctrl_path = project_path[:controllers] + class_name_to_route(ctrl_name) + '/'
    File.directory?(ctrl_path) ||
      fail("#{ctrl_name} does not exists. Please create it first")

    name.nil? || name.empty? && fail("Please provide route name via second argument")
    path_rules = E__PATH_RULES.inject({}) do |map,(r,s)|
      map.merge /#{Regexp.escape s}/ => r.source
    end
    action = action_name_to_route(name, path_rules)
    validate_action_name(action)

    file = ctrl_path + action + '.rb'
    File.exists?(file) && fail("#{name} action already exists")

    before, ctrl_name, after = controller_source_code(ctrl_name)

    source_code, i = [], '  ' * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name}"
    ["def #{action}", INDENTATION, "end"].each do |line|
      source_code << (i + INDENTATION + line)
    end
    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")

    putm "Writing #{file.sub(project_path[:root], '')}"
    putm source_code
    File.open(file, 'w') {|f| f << source_code}
  end

  private
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

  def putm msg = ''
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

  def in_app_folder?
    File.exists?(dst_path[:controllers]) ||
      fail("Current folder does not seem to contain a Espresso application")
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
