class << E

  def app;           @__e__app    end
  def routes;        @__e__routes end
  def hosts;         @__e__hosts || {}  end
  def action_setup;  @__e__action_setup end
  def rewrite_rules; @__e__rewrite_rules || []  end
  def mapped?;       @__e__base_url end
  def mounted?;      @__e__mounted || @__e__app end

  # build URL from given action name(or path) and consequent params
  # @return [String]
  #
  def route *args
    mounted? || raise("`route' works only on mounted controllers. Please consider to use `base_url' instead.")
    return base_url if args.size == 0
    (route = self[args.first]) && args.shift
    EUtils.build_path(route || base_url, *args)
  end
  
  def base_url
    @__e__base_url || default_route
  end
  alias baseurl base_url

  def canonicals
    @__e__canonicals || []
  end

  def default_route
    @__e__default_route ||= EUtils.class_to_route(self.name).freeze
  end

  # @example
  #    class Forum < E
  #      format '.html', '.xml'
  #
  #      def posts
  #      end
  #    end
  #
  #    App[:posts]             #=> /forum/posts
  #    App['posts.html']       #=> /forum/posts.html
  #    App['posts.xml']        #=> /forum/posts.xml
  #    App['posts.json']       #=> nil
  #
  def [] action_or_action_with_format
    mounted? || raise("`[]' method works only on mounted controllers")
    @__e__route_by_action[action_or_action_with_format] ||
      @__e__route_by_action_with_format[action_or_action_with_format]
  end

  def path_rules
    @__e__sorted_path_rules ||= begin
      rules = @__e__path_rules || EConstants::PATH_RULES
      Hash[rules.sort {|a,b| b.first.source.size <=> a.first.source.size}].freeze
    end
  end

  def alias_actions
    @__e__alias_actions || {}
  end

  def formats action
    (@__e__expanded_formats || {})[action] || []
  end

  def error_handler error_code
    ((@__e__error_handlers || {}).find {|k,v| error_code == k} || []).last
  end

  def setup_aliases position, action
    if position == :a
      (@__e__before_aliases || {})[action] || []
    elsif position == :z
      (@__e__after_aliases  || {})[action] || []
    else
      []
    end
  end

  def setups position, action, format
    return [] unless (s = @__e__expanded_setups) && (s = s[position]) && (s = s[action])
    s[format] || []
  end

  def middleware
    @__e__middleware || []
  end

  def subcontrollers
    (@__e__subcontrollers || []).uniq
  end

end
