class E

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
  def engine engine, engine_opts = {}
    EUtils.register_extra_engines!
    engine = EConstants::VIEW__ENGINE_BY_SYM[engine] ||
      raise(ArgumentError, '%s engine not supported. Supported engines: %s' %
        [engine, EConstants::VIEW__ENGINE_BY_SYM.keys.join(', ')])
    @__e__engine = [engine, engine_opts].freeze
  end
  define_setup_method :engine

  # set the extension used by templates
  def engine_ext ext
    @__e__engine_ext = ext.freeze
  end
  define_setup_method :engine_ext

  # set the layout to be used by some or all actions.
  #
  # @note
  #   by default no layout will be rendered.
  #   if you need layout, use `layout` to set it.
  #
  # @example set :master layout for :index and :register actions
  #
  #    class Example < E
  #      setup :index, :register do
  #        layout :master
  #      end
  #    end
  #
  # @example instruct :plain and :json actions to not use layout
  #
  #    class Example < E
  #      setup :plain, :json do
  #        layout false
  #      end
  #    end
  #
  # @example use a block for layout
  #
  #    class Example < E
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
    @__e__layout = layout == false ? nil : [layout, proc].freeze
  end
  define_setup_method :layout

  # set custom path for templates.
  # default value: app_root/view/
  def view_path path
    @__e__view_path = path.freeze
  end
  define_setup_method :view_path

  def view_fullpath path
    @__e__view_fullpath = path.freeze
  end
  define_setup_method :view_fullpath

  # allow setting view prefix
  #
  # @note defaults to controller's base_url
  #
  # @example  :index action will render 'view/admin/reports/index.EXT' view,
  #           regardless of base_url
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
    @__e__view_prefix = path.freeze
  end
  define_setup_method :view_prefix

  # set custom path for layouts.
  # default value: view path
  #
  # @note should be relative to view path
  def layouts_path path
    @__e__layouts_path = path.freeze
  end
  alias layout_path layouts_path
  define_setup_method :layouts_path
  define_setup_method :layout_path

end
