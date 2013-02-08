class EspressoGenerator

  private
  def generate_route ctrl_name, name, args, setups = {}

    action_file, action = valid_action?(ctrl_name, name)

    File.exists?(action_file) && fail("#{name} action/route already exists")

    before, ctrl_name, after = namespace_to_source_code(ctrl_name, false)

    source_code, i = [], '  ' * before.size
    before.each {|s| source_code << s}
    source_code << "#{i}class #{ctrl_name}"

    if format = setups[:format]
      source_code << "#{i + INDENT}format_for :#{action}, '#{format}'"
    end
    if setups.any?
      source_code << "#{i + INDENT}before :#{action} do"
      if engine = setups[:engine]
        source_code << "#{i + INDENT*2}engine :#{engine}"
        update_gemfile :engine => engine
      end
      source_code << "#{i + INDENT}end"
      source_code << ""
    end

    args = args.any? ? ' ' + args.map {|a| a.sub(/\,\Z/, '')}.join(', ') : ''
    source_code << (i + INDENT + "def #{action + args}")
    action_source_code = ["render"]
    if block_given?
      action_source_code = yield
      action_source_code.is_a?(Array) || action_source_code = [action_source_code]
    end
    action_source_code.each do |line|
      source_code << (i + INDENT*2 + line.to_s)
    end
    source_code << (i + INDENT + "end")

    source_code << "#{i}end"
    after.each  {|s| source_code << s}
    source_code = source_code.join("\n")
    o
    o '--- Generating "%s" route ---' % name
    o "Writing #{unrootify action_file}"
    o source_code
    File.open(action_file, 'w') {|f| f << source_code}
  end
end
