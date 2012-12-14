class << E

  # @example - use Haml for all actions
  #    engine :Haml
  #
  # @example - use Haml only for :news and :articles actions
  #    class App < E
  #      # ...
  #      setup :news, :articles do
  #        engine :Haml
  #      end
  #    end
  #
  # @example engine with opts
  #    engine :Haml, :some_engine_argument, some_option: 'some value'
  #
  # @param [Symbol] engine
  #   accepts any of Tilt supported engine
  # @param [String] *args
  #   any args to be passed to engine at initialization
  def engine engine, *engine_args
    engine! engine, *engine_args << true
  end

  def engine! engine, *engine_args
    return if locked?
    engine?

    register_slim_engine! if engine == :Slim

    keep_existing = engine_args.delete(true)
    setup__actions.each do |action|
      next if @view__engine[action] && keep_existing

      engine_class = ::Tilt.const_get("#{engine}Template".to_sym)
      engine_opts = engine_args.inject({}) do |args, a|
        a.is_a?(Hash) ? args.merge(a) : args.merge(a => true)
      end.freeze
      @view__engine[action] = [engine_class, engine_opts]
    end
  end

  def engine? action = nil
    @view__engine ||= {}
    @view__engine[action] || @view__engine[:*] || [::Tilt::ERBTemplate, {}]
  end

  # set the extension used by templates
  def engine_ext ext
    engine_ext! ext, true
  end

  def engine_ext! ext, keep_existing = false
    return if locked?
    engine_ext?
    setup__actions.each do |a|
      next if @view__engine_ext[a] && keep_existing
      @view__engine_ext[a] = (normalized_ext ||= normalize_path('.' + ext.to_s.sub(/\A\./, '')).freeze)
    end
  end

  def engine_ext? action = nil
    @view__engine_ext ||= {}
    @view__engine_ext[action] || @view__engine_ext[:*] || engine_default_ext?(engine?(action).first)
  end

  engine_default_ext = ::Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
    inject({}) { |m, i| i.last.each { |e| m.update e => ('.' + i.first) }; m }
  define_method :engine_default_ext? do |engine|
    engine_default_ext[engine]
  end

  # set the layout to be used by some or all actions.
  #
  # @note
  #   by default no layout will be rendered.
  #   if you need layout, use `layout` to set it.
  #
  # @example set :master layout for :index and :register actions
  #
  #    class Example < E
  #      # ...
  #      setup :index, :register do
  #        layout :master
  #      end
  #    end
  #
  # @example instruct :plain and :json actions to not use layout
  #
  #    class Example < E
  #      # ...
  #      setup :plain, :json do
  #        layout false
  #      end
  #    end
  #
  # @example use a block for layout
  #
  #    class Example < E
  #      # ...
  #      layout do
  #        <<-HTML
  #            header
  #            <%= yield %>
  #            footer
  #        HTML
  #      end
  #    end
  #
  # @param layout
  # @param [Proc] &proc
  def layout layout = nil, &proc
    layout! layout, true, &proc
  end

  def layout! layout = nil, keep_existing = false, &proc
    return if locked?
    layout?
    layout = normalize_path(layout.to_s).freeze unless layout == false
    setup__actions.each do |a|
      next if @view__layout[a] && keep_existing

      # if action provided with format, adding given format to layout name
      if layout && a.is_a?(String) && (format = ::File.extname(a)).size > 0
        layout = layout + format
      end
      @view__layout[a] = [layout, proc]
    end
  end

  def layout? action = nil
    @view__layout ||= {}
    @view__layout[action] || @view__layout[:*]
  end

  # set custom path for templates.
  # default value: app_root/view/
  def view_path path
    view_path! path, :keep_existing
  end

  def view_path! path, keep_existing = false
    return if locked? || (@view__path && keep_existing)
    path = normalize_path(path.to_s + '/').sub(/\/+\Z/, '/')
    path =~ /\A\// ?
      view_fullpath!(path, keep_existing) :
      @view__path = path.freeze
  end

  def view_path?
    @view__computed_path ||= begin
      (p = view_fullpath?) ? p :
        (app.root + (@view__path || E::VIEW__DEFAULT_PATH)).freeze
    end
  end

  def view_fullpath path
    view_fullpath! path, :keep_existing
  end

  def view_fullpath! path, keep_existing = false
    return if locked? || (@view__fullpath && keep_existing)
    @view__fullpath = path ?
      normalize_path(path.to_s + '/').sub(/\/+\Z/, '/').freeze : path
  end

  def view_fullpath?
    @view__fullpath
  end

  # allow setting view prefix for this controller
  #
  # @note defaults to controller's base_url
  #
  # @example :index-action will render 'view/admin/reports/index.EXT' view, regardless of base_url
  #
  #    class Reports < E
  #      map '/reports'
  #      view_prefix 'admin/reports'
  #      # ...
  #      def index
  #        render
  #      end
  #
  #    end
  #
  # @param string
  def view_prefix path
    view_prefix! path, :keep_existing
  end
  
  def view_prefix! path, keep_existing = false
    return if locked? || (@view__prefix && keep_existing)
    @view__prefix = path ?
      normalize_path(path.to_s + '/').sub(/\/+\Z/, '/').freeze : path
  end

  def view_prefix?
    @view__prefix || base_url
  end

  # set custom path for layouts.
  # default value: view path
  # @note should be relative to view path
  def layouts_path path
    layouts_path!(path, :keep_existing)
  end
  alias :layout_path :layouts_path

  def layouts_path! path, keep_existing = false
    return if locked? || (@view__layouts_path && keep_existing)
    @view__layouts_path = normalize_path(path.to_s + '/').freeze
  end

  def layouts_path?
    @view__layouts_path ||= ''.freeze
  end

  def register_slim_engine!
    Object.const_defined?(:Slim) ||
      raise(ArgumentError, "Please load Slim engine before using it")
    unless ::Tilt.const_defined?(:SlimTemplate)
      ::Tilt.const_set :SlimTemplate, ::Slim::Template
      ::Tilt.register  ::Tilt::SlimTemplate, 'slim'
      ::E::E__ENGINE_MAP['slim'] = ::Tilt::SlimTemplate
    end
  end
end
