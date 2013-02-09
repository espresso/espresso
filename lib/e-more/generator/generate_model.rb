class EspressoGenerator

  def generate_model name, setups = {}

    name.nil? || name.empty? && fail("Please provide model name via second argument")
    before, model_name, after = namespace_to_source_code(name)
    
    superclass, insertions = '', []
    if orm = setups[:orm] || Cfg[:orm]
      update_gemfile :orm => orm
      orm =~ /\Aa/i && superclass = ' < ActiveRecord::Base'
      orm =~ /\As/i && superclass = ' < Sequel::Model'
      if orm =~ /\Ad/i
        insertions << 'include DataMapper::Resource'
        insertions << ''
        insertions <<'property :id, Serial'
      end
    end
    insertions << ''

    source_code, i = [], INDENT * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{model_name + superclass}"

    insertions.each do |line|
      source_code << (i + INDENT + line.to_s)
    end

    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    
    path = dst_path[:models] + class_name_to_route(name)
    File.exists?(path) && fail("#{name} model already exists")
    
    o
    o '--- Generating "%s" model ---' % name
    dir = File.dirname(path)
    if File.exists?(dir)
      File.directory?(dir) || fail("#{unrootify dir} should be a directory")
    else
      o "Creating #{unrootify dir}/"
      FileUtils.mkdir_p(dir)
    end
    file = path + '.rb'
    o "Writing  #{unrootify file}"
    o source_code
    o
    File.open(file, 'w') {|f| f << source_code}
  end
end
