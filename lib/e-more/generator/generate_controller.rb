class EspressoGenerator

  private
  def generate_controller name, route = nil, setups = {}
    route.is_a?(Hash) && (setups = route) && (route = nil)

    name.nil? || name.empty? && fail("Please provide controller name via second argument")
    before, ctrl_name, after = namespace_to_source_code(name)

    source_code, i = [], INDENT * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name} < E"
    if route
      source_code << "#{i + INDENT}map '#{route}'"
    end
    if engine = setups[:engine]
      source_code << "#{i + INDENT}engine :#{engine}"
      update_gemfile :engine => engine
    end
    if format = setups[:format]
      source_code << "#{i + INDENT}format '#{format}'"
    end
    source_code << INDENT

    ["def index", INDENT + "render", "end"].each do |line|
      source_code << (i + INDENT + line.to_s)
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
end
