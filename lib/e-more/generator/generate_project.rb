class EspressoGenerator

  def generate_project name, setups = {}

    name.nil? || name.empty? && fail("Please provide project name via second argument")
    name =~ /\.\.|\// && fail("Project name can not contain slashes nor ..")

    project_path = dst_path(:append => name)
    File.exists?(project_path[:root]) && fail("#{name} already exists")

    o
    o '--- Generating "%s" project ---' % name

    folders, files = Dir.glob(@src_path[:base] + '**/{*,.pryrc}').partition do |entry|
      File.directory?(entry)
    end

    FileUtils.mkdir(project_path[:root])
    o "  #{name}/"
    folders.each do |folder|
      path = unrootify(folder, @src_path[:base])
      o "  `- #{path}"
      FileUtils.mkdir(project_path[:root] + path)
    end

    files.each do |file|
      path = unrootify(file, @src_path[:base])
      o "  Writing #{path}"
      FileUtils.cp(file, project_path[:root] + path)
    end

    update_config  setups, project_path
    update_gemfile setups, project_path
    update_rakefile setups, project_path
    update_db_setup_file setups, project_path
  end
end
