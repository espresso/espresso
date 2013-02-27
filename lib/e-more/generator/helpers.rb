class EspressoGenerator

  private

  def extract_setup input
    input.scan(/:(.+)/).flatten.last
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
    YAML.dump(data).split("\n").each {|l| o "+ " + l}
    o
    File.open(file, 'w') {|f| f << YAML.dump(cfg)}
  end

  def update_gemfile data, project_path = nil
    return if data.empty?
    project_path ||= dst_path
    
    file = project_path[:root] + 'Gemfile'
    gems, existing_gems = [], extract_gems(file)

    [data[:orm], data[:engine]].compact.each do |gem|
      gemfile = @src_path[:gemfiles] + gem.to_s + '.rb'
      if File.file?(gemfile)
        extract_gems(gemfile).each_pair do |g,d|
          gems << d unless existing_gems[g]
        end
      else
        gem = underscore(gem.to_s)
        gems << ("gem '%s'" % gem) unless existing_gems[gem]
      end
    end
    return if gems.empty?

    o "Updating #{unrootify file}"
    File.open(file, 'a') do |f|
      gems.each do |g|
        o "+ %s" % g
        f << g
        f << "\n"
      end
    end
  end

  def update_db_setup_file setups, project_path
    if orm = setups[:orm]
      src = @src_path[:database] + orm.to_s + '.rb'
      dst = project_path[:base]  + 'database.rb'
      o
      o "Writing #{unrootify dst}"
      File.readlines(src).each {|l| o "+ " + l.chomp}
      FileUtils.cp src, dst
    end
  end

  def extract_gems file
    File.readlines(file).select {|l| l.strip =~ /\Agem/}.inject({}) do |map,l|
      map.merge l.scan(/gem\W+([\w|\-]+)\W+/).flatten.first => l.strip
    end
  end

  def valid_orm? orm
    return unless orm.is_a?(String)
    case
    when orm =~ /\Aa/i
      :ActiveRecord
    when orm =~ /\Ad/i
      :DataMapper
    when orm =~ /\As/i
      :Sequel
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

    ctrl = name.split('::').map(&:to_sym).inject(Object) do |ns,c|
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
    action = action_to_route(name, path_rules)
    validate_action_name(action)
    action_file = ctrl_path + action + '_action.rb'
    [action_file, action]
  end

  def fail msg = nil
    if msg
      o
      o '!!! %s !!!' % msg
      o
    end
    exit 1
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
      i = INDENT * before.size
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
