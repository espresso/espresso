class E

  [:compiler_pool, :clear_compiler!].each do |m|
    define_method m do |*args, &proc|
      app.send m, *args, &proc
    end
  end

  def view_path?
    @__e__computed_view_path ||= begin
      (fullpath = view_fullpath?) ? fullpath :
        File.join(app.root, @__e__view_path || EConstants::VIEW__DEFAULT_PATH).freeze
    end
  end

  def view_fullpath?
    @__e__view_fullpath
  end

  def view_prefix?
    @__e__view_prefix || default_route
  end

  def layouts_path?
    @__e__layouts_path || ''
  end

  def engine?
    @__e__engine || EConstants::VIEW__DEFAULT_ENGINE
  end

  def engine_ext?
    @__e__engine_ext || EConstants::VIEW__EXT_BY_ENGINE[engine?.first] || ''
  end

  def engine_ext_with_format
    @__e__engine_ext_with_format ||= (format.to_s + engine_ext?).freeze
  end

  def layout?
    @__e__layout
  end

  # returns full path to templates.
  # if any args given they are `File.join`-ed and appended to returned path.
  #
  # @note this method will not make use of `view_prefix`,
  #       thus you should provide full path to template, relative to `view_path` of course
  #
  def path_to_templates *args
    explicit_view_path view_path?, *args
  end

  # returns full path to layouts.
  # if any args given they are `File.join`-ed and appended to returned path.
  def path_to_layouts *args
    explicit_view_path view_path?, layouts_path?, *args
  end

  def explicit_view_path *args
    EView__ExplicitPath.new File.join(*args)
  end

  # render a template with layout(if any defined).
  # if no template given, it will use current action name as template.
  # extension will be automatically added, based on format and engine extension.
  def render *args, &proc
    template, scope, locals = __e__engine_arguments(args)
    engine_class, engine_opts = engine?
    engine_args = proc ? [engine_opts] : [__e__template(template), engine_opts]
    output = __e__engine_instance(engine_class, *engine_args, &proc).render(scope, locals)

    layout, layout_proc = layout?
    return output unless layout || layout_proc

    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(layout), engine_opts]
    __e__engine_instance(engine_class, *engine_args, &layout_proc).render(scope, locals) { output }
  end
  
  # render a template without layout.
  # if no template given, it will use current action name as template.
  # extension will be automatically added, based on format and engine extension.
  def render_partial *args, &proc
    template, scope, locals = __e__engine_arguments(args)
    engine_class, engine_opts = engine?
    engine_args = proc ? [engine_opts] : [__e__template(template), engine_opts]
    __e__engine_instance(engine_class, *engine_args, &proc).render(scope, locals)
  end
  alias render_p render_partial

  # render a layout.
  # if no layout given, it will use the layout defined for current action(if any).
  # extension will be automatically added, based on format and engine extension.  
  def render_layout *args, &proc
    layout, scope, locals = __e__engine_arguments(args, nil)
    layout, layout_proc = layout ? layout : layout?
    layout || layout_proc || raise('No explicit layout given nor implicit layout found' % action)
    engine_class, engine_opts = engine?
    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(layout), engine_opts]
    __e__engine_instance(engine_class, *engine_args, &layout_proc).render(scope, locals, &(proc || Proc.new {''}))
  end
  alias render_l render_layout

  # render a template by name.
  # it requires full template name, eg. with extension.
  def render_file template, *args
    template = path_to_templates(template) unless template.instance_of?(EView__ExplicitPath)
    render_partial template, *args
  end
  alias render_f render_file

  # render a layout.
  # it requires full layout name, eg. with extension.
  def render_layout_file template, *args, &proc
    template = path_to_layouts(template) unless template.instance_of?(EView__ExplicitPath)
    render_layout template, *args, &proc
  end
  alias render_lf render_layout_file

  EConstants::VIEW__ENGINE_MAPPER.each_key do |ext|
    __e__adhoc_engine_ext = ext.sub('.', '')
    
    define_method 'render_%s' % __e__adhoc_engine_ext do |*args, &proc|
      template, scope, locals = __e__engine_arguments(args)
      engine_args = proc ? [] : [__e__template(template, ext)]
      output = __e__engine_instance(EConstants::VIEW__ENGINE_MAPPER[ext], *engine_args, &proc).render(scope, locals)

      layout, layout_proc = layout?
      return output unless layout || layout_proc

      engine_args = layout_proc ? [] : [__e__layout_template(layout, ext)]
      __e__engine_instance(EConstants::VIEW__ENGINE_MAPPER[ext], *engine_args, &layout_proc).render(scope, locals) {output}
    end

    define_method 'render_%s_partial' % __e__adhoc_engine_ext do |*args, &proc|
      template, scope, locals = __e__engine_arguments(args)
      engine_args = proc ? [] : [__e__template(template, ext)]
      __e__engine_instance(EConstants::VIEW__ENGINE_MAPPER[ext], *engine_args, &proc).render(scope, locals)
    end
    alias_method 'render_%s_p' % __e__adhoc_engine_ext, 'render_%s_partial' % __e__adhoc_engine_ext

    define_method 'render_%s_layout' % __e__adhoc_engine_ext do |*args, &proc|
      layout, scope, locals = __e__engine_arguments(args, nil)
      layout, layout_proc = layout ? layout : layout?
      layout || layout_proc || raise('No explicit layout given nor implicit layout found' % action)
      engine_args = layout_proc ? [] : [__e__layout_template(layout, ext)]
      __e__engine_instance(EConstants::VIEW__ENGINE_MAPPER[ext], *engine_args, &layout_proc).render(scope, locals, &(proc || Proc.new {''}))
    end
    alias_method 'render_%s_l' % __e__adhoc_engine_ext, 'render_%s_layout' % __e__adhoc_engine_ext

    define_method 'render_%s_file' % __e__adhoc_engine_ext do |template, *args|
      template = path_to_templates(template) unless template.instance_of?(EView__ExplicitPath)
      self.send 'render_%s_partial' % __e__adhoc_engine_ext, template, *args
    end
    alias_method 'render_%s_f' % __e__adhoc_engine_ext, 'render_%s_file' % __e__adhoc_engine_ext

    define_method 'render_%s_layout_file' % __e__adhoc_engine_ext do |template, *args, &proc|
      template = path_to_layouts(template) unless template.instance_of?(EView__ExplicitPath)
      self.send 'render_%s_layout' % __e__adhoc_engine_ext, template, *args, &proc
    end
    alias_method 'render_%s_lf' % __e__adhoc_engine_ext, 'render_%s_layout_file' % __e__adhoc_engine_ext

  end

  private

  def __e__engine_arguments args, template = action
    scope, locals = self, {}
    args.compact.each do |arg|
      case arg
      when String
        template = arg
      when Symbol
        template = arg.to_s
      when Hash
        locals.update arg
      else
        scope = arg
      end
    end
    [template, scope, locals]
  end

  def __e__engine_instance engine, *args, &proc
    if compiler_pool && (tpl = args.first).is_a?(String)
      ((compiler_pool[tpl]||={})[File.mtime(tpl).to_i]||={})[engine.__id__] ||=
        engine.new(*args, &proc)
    else
      engine.new(*args, &proc)
    end
  end

  def __e__template template, ext = engine_ext_with_format
    return template if template.instance_of?(EView__ExplicitPath)
    File.join(view_path?, view_prefix?, template.to_s) << ext
  end

  def __e__layout_template layout, ext = engine_ext_with_format
    return layout if layout.instance_of?(EView__ExplicitPath)
    File.join(view_path?, layouts_path?, layout.to_s) << ext
  end

end

class EView__ExplicitPath < String; end
