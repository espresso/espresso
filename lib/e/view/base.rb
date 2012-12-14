class E

  E__ENGINE_MAP = ::Tilt.mappings.inject({}) do |map, s|
    s.last.each { |e| map.update e.to_s.split('::').last.sub(/Template\Z/, '').downcase => e }
    map
  end
  # Slim adapter not shipped with Tilt,
  # so adding Slim to map to be sure adhoc methods defined at loadtime
  E__ENGINE_MAP['slim'] = nil unless E__ENGINE_MAP.has_key?('slim')

  # returns the path defined at class level.
  # if some path given it will be appended to global path.
  # if multiple paths given they will be `File.join`-ed and appended to global path.
  def view_path *args
    view_path_builder self.class.view_path?, *args
  end

  def view_path_builder *args
    ::EspressoFrameworkExplicitViewPath.new ::File.join(*args)
  end

  # returns full path to layouts.
  # if any args given they are `File.join`-ed and appended to returned path.
  def layouts_path *args
    ::EspressoFrameworkExplicitViewPath.new ::File.join(self.class.view_path?, self.class.layouts_path?, *args)
  end
  alias :layout_path :layouts_path

  # Note on rendering: **Espresso wont support custom file extensions**,
  # so you can not render a template like this: `render "template.haml"`.
  # Instead use `render "template"` and the extension will be added automatically,
  # based on extension given or computed at class level.
  #
  # Espresso will guess extension by used engine, like '.haml' for Haml, '.erb' for Erubis etc.
  # If your templates uses a custom extension, set it via `engine_ext`.
  #   
  # However, if you have a file with a extension that is not typical for used engine
  # nor match the extension given via `engine_ext`, please consider to rename the file.
  #
  # Computing file extensions would add extra unneeded overhead.
  # The probability of custom extensions are ephemeral
  # and it is quite irrational to slow down an entire framework 
  # just to handle such a negligible probability.

  def render *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    engine_args = proc ? [engine_opts] : [__e__template(controller, action_or_template), engine_opts]
    output = __e__engine_instance(compiler_key, engine_class, *engine_args, &proc).render(scope, locals)

    # looking for layout of given action
    # or the one of current action
    layout, layout_proc = controller.layout?(controller[action_or_template] ? action_or_template : action_with_format)
    return output unless layout || layout_proc

    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(controller, layout, controller.engine_ext?(action_or_template)), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals) { output }
  end

  def render_partial *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    engine_args = proc ? [engine_opts] : [__e__template(controller, action_or_template), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &proc).render(scope, locals)
  end
  alias render_p render_partial

  def render_layout *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    # render layout of given action
    # or use given action_or_template as template name
    layout, layout_proc = controller[action_or_template] ? controller.layout?(action_or_template) : action_or_template
    layout || layout_proc || raise('seems there are no layout defined for %s#%s action' % [controller, action_or_template])
    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(controller, layout, controller.engine_ext?(action_or_template)), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals, &(proc || proc() { '' }))
  end
  alias render_l render_layout

  E__ENGINE_MAP.each_key do |suffix, engine|

    # this can be easily done via `define_method`,
    # however, ruby 1.8 does not support args with default values on procs
    # TODO: use `define_method` when 1.8 support dropped.
    class_eval <<-RUBY

    def render_#{suffix} *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      engine_args = proc ? [] : [__e__template(controller, action_or_template, '.#{suffix}')]
      output = __e__engine_instance(compiler_key, E__ENGINE_MAP['#{suffix}'], *engine_args, &proc).render(scope, locals)

      # looking for layout of given action
      # or the one of current action
      layout, layout_proc = controller.layout?(controller[action_or_template] ? action_or_template : action_with_format)
      return output unless layout || layout_proc

      engine_args = layout_proc ? [] : [__e__layout_template(controller, layout, '.#{suffix}')]
      __e__engine_instance(compiler_key, E__ENGINE_MAP['#{suffix}'], *engine_args, &layout_proc).render(scope, locals) { output }
    end

    def render_#{suffix}_partial *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      engine_args = proc ? [] : [__e__template(controller, action_or_template, '.#{suffix}')]
      __e__engine_instance(compiler_key, E__ENGINE_MAP['#{suffix}'], *engine_args, &proc).render(scope, locals)
    end
    alias render_#{suffix}_p render_#{suffix}_partial

    def render_#{suffix}_layout *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      # render layout of given action
      # or use given action_or_template as template name
      layout, layout_proc = controller[action_or_template] ? controller.layout?(action_or_template) : action_or_template
      layout || layout_proc || raise('seems there are no layout defined for %s#%s action' % [controller, action_or_template])
      engine_args = layout_proc ? [] : [__e__layout_template(controller, layout, '.#{suffix}')]
      __e__engine_instance(compiler_key, E__ENGINE_MAP['#{suffix}'], *engine_args, &layout_proc).render(scope, locals, &(proc || proc() { '' }))
    end
    alias render_#{suffix}_l render_#{suffix}_layout
      
    RUBY

  end

  private

  def compiler_cache key, &proc
    self.class.app.send __method__, key, &proc
  end

  def clear_compiler! *args
    self.class.app.send __method__, *args
  end

  def clear_compiler_like! *args
    self.class.app.send __method__, *args
  end

  def __e__engine_params *args
    controller, action_or_template, scope, locals = self.class, action_with_format, self, {}
    args.compact.each do |arg|
      case
        when ::AppetiteUtils.is_app?(arg)
          controller = arg
        when arg.is_a?(Symbol), arg.is_a?(String)
          action_or_template = arg
        when arg.is_a?(Hash)
          locals = arg
        else
          scope = arg
      end
    end
    compiler_key = locals.delete ''
    [controller, action_or_template, scope, locals, compiler_key]
  end

  def __e__engine_instance compiler_key, engine, *args, &proc
    if compiler_key
      __e__compiler_key_cached_instance(compiler_key, engine, *args, &proc)
    else
      __e__mtime_cached_instance(engine, *args, &proc)
    end
  end

  def __e__compiler_key_cached_instance(compiler_key, engine, *args, &proc)
    compiler_cache [compiler_key, engine.__id__, args.hash, proc && proc.__id__] do
      engine.new(*args, &proc)
    end
  end

  def __e__mtime_cached_instance(engine, *args, &proc)
    if args.first.instance_of?(String) or args.first.instance_of?(EspressoFrameworkExplicitViewPath)
      mtime = File.mtime(args.first).to_i
      compiler_cache [mtime, engine.__id__, args.hash, proc && proc.__id__] do
        engine.new(*args, &proc)
      end
    else
      engine.new(*args, &proc)
    end
  end

  def __e__template controller, action_or_template, ext = nil
    if action_or_template.instance_of?(::EspressoFrameworkExplicitViewPath)
      action_or_template
    else
      ::File.join controller.view_path?, # controller's path to templates
        controller.view_prefix?,         # controller's route
        action_or_template.to_s          # given template
    end << (ext || controller.engine_ext?(action_or_template))  # given or computed extension
  end

  def __e__layout_template controller, layout, ext
    if layout.instance_of?(EspressoFrameworkExplicitViewPath)
      layout
    else
      ::File.join controller.view_path?, # controller's path to templates
        controller.layouts_path?,        # controller's path to layouts
        layout.to_s                      # given template
    end << (ext || '')                   # given or computed extension
  end

end

# checking whether explicit path given
class EspressoFrameworkExplicitViewPath < String; end
