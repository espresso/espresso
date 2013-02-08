class EspressoGenerator

  private

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
end
