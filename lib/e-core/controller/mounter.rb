class << E

  def run *args
    mount.run *args
  end

  def call env
    mount.call(env)
  end

  # used when mounted manually
  #
  # @param [Array]  roots first arg treated as base URL,
  #                       consequent ones treated as canonical URLs.
  # @param [Proc]   setup setup block. to be executed at class level
  #
  def mount *roots, &setup
    @__e__app ||= EBuilder.new.mount(self, *roots, &setup).to_app
  end

  # used when mounted from an E instance
  #
  # @param [Object] app EBuilder instance
  #
  def mount! app
    return if mounted?
    @__e__app = app

    # Important - expand_formats! should run before expand_setups!
    expand_formats!
    expand_setups!
    generate_routes!
    lock!

    @__e__mounted = true
  end

  # use this when you do not want some controller(s) to be automounted
  def reject_automount!
    @reject_automount = true
  end
  def accept_automount?
    true unless @reject_automount
  end

  # remap served root(s) by prepend given path to controller's root.
  #
  # @note Important: all actions should be defined before re-mapping occurring
  #
  # @example
  #   class Forum < E
  #     map '/forum', '/forums'
  #     # ...
  #   end
  #
  #   app = E.new.mount(Forum, '/new-root')
  #   # app will serve:
  #   #   - /new-root/forum
  #   #   - /new-root/forums
  #
  def remap! root, opts = {}
    return if mounted?
    new_canonicals = canonicals.map {|c| EUtils.rootify_url(root, c)}
    map! EUtils.rootify_url(root, base_url), *new_canonicals.uniq, opts
  end

  def global_setup! &setup
    @__e__setup_container = :global
    self.class_exec self, &setup
    @__e__setup_container = nil
  end

  def external_setup! &setup
    @__e__setup_container = :external
    self.class_exec &setup
    @__e__setup_container = nil
  end

  private

  def map! *args
    opts = args.last.is_a?(Hash) ? args.pop : {}
    @__e__base_url   = EUtils.rootify_url(args.shift.to_s).freeze
    @__e__canonicals = args.map { |p| EUtils.rootify_url(p.to_s) }.freeze
    (@__e__hosts ||= {}).update EUtils.extract_hosts(opts)
  end

  def lock!
    self.instance_variables.reject {|v| v.to_s == '@__e__app' }.each do |var|
      (var.to_s =~ /@__e__/) && (val = self.instance_variable_get(var)) && val.freeze
    end
  end

  def reset_routes_data!
    @__e__routes = {}
    @__e__action_setup = {}
    @__e__route_by_action, @__e__route_by_action_with_format = {}, {}
  end
 
  def generate_routes!
    reset_routes_data!
    persist_action_setups!
    
    public_actions.each do |action|
      @__e__action_setup[action].each_pair do |request_method, setup|
        set_action_routes(setup)
        set_canonical_routes(setup)
        set_alias_routes(setup)
      end
    end
  end

  def persist_action_setups!
    public_actions.each do |action|
      action_setup = generate_action_setup(action)
      action_setup.values_at(:action, :action_name).each do |matcher|
        (@__e__action_setup[matcher] ||= {})[action_setup[:request_method]] = action_setup

        @__e__route_by_action[matcher] = action_setup[:path]
        formats(action).each do |format|
          @__e__route_by_action_with_format[matcher.to_s + format] = action_setup[:path] + format
        end
      end
    end
  end

  def set_action_routes action_setup
    set_route(action_setup[:path], action_setup)
    set_route(base_url, action_setup) if action_setup[:action_name] == EConstants::INDEX_ACTION
  end

  def set_canonical_routes action_setup
    canonicals.each do |c|
      c_route = EUtils.canonical_to_route(c, action_setup)
      c_setup = action_setup.merge(:path => c_route, :canonical => action_setup[:path])
      set_route(c_route, c_setup)
    end
  end

  def set_alias_routes action_setup
    aliases = alias_actions[action_setup[:action]] || []

    aliases.each do |a|
      a_route = EUtils.rootify_url(base_url, a)
      a_setup = action_setup.merge(:path => a_route)
      set_route(a_route, a_setup)
    end

    canonicals.each do |c|
      aliases.each  do |a|
        a_route = EUtils.rootify_url(c, a)
        a_setup = action_setup.merge(:path => a_route, :canonical => action_setup[:path])
        set_route(a_route, a_setup)
      end
    end
  end

  def set_route route, setup
    regexp = EUtils.route_to_regexp(route, formats: setup[:formats].keys)
    (@__e__routes[regexp] ||= {})[setup[:request_method]] = setup
  end

  # avoid regexp operations at runtime
  # by turning Regexp and * matchers into real action names at loadtime.
  # also this will match setups by formats.
  #
  # any number of arguments accepted.
  # if zero arguments given,
  #   the setup will be effective for all actions.
  # when an argument is a symbol,
  #   the setup will be effective only for action with same name as given symbol.
  # when an argument is a Regexp,
  #   the setup will be effective for all actions matching given Regex.
  # when an argument is a String it is treated as format,
  #   and the setup will be effective only for actions that serve given format.
  # any other arguments ignored.
  #
  # @note when passing a format as matcher:
  #       if URL has NO format, format-related setups are excluded.
  #       when URL does contain a format, ALL action-related setups becomes effective.
  #
  # @note Regexp matchers are used ONLY to match action names,
  #       not formats nor action names with format.
  #       thus, NONE of this will work: /\.(ht|x)ml/, /.*pi\.xml/  etc.
  #
  # @example
  #   class App < E
  #
  #     format '.json', '.xml'
  #
  #     layout :master
  #
  #     setup 'index.xml' do
  #       # ...
  #     end
  #
  #     setup /api/ do
  #       # ...
  #     end
  #
  #     setup '.json', 'read.xml' do
  #       # ...
  #     end
  #
  #     def index
  #       # on /index, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #
  #       # on /index.json, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup '.json'...`  (matched via .json)
  #       #
  #       # on /index.xml, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup 'index.xml'...`  (matched via index.xml)
  #     end
  #
  #     def api
  #       # on /api, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup /api/...`  (matched via /api/)
  #       #
  #       # on /api.json, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup /api/...`  (matched via /api/)
  #       #   - `setup '.json'...`  (matched via .json)
  #       #
  #       # on /api.xml, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup /api/...`  (matched via /api/)
  #     end
  #
  #     def read
  #       # on /read, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #
  #       # on /read.json, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup '.json'...`  (matched via .json)
  #       #
  #       # on /read.xml, will use following setups:
  #       #   - `layout ...` (matched via *)
  #       #   - `setup ... 'read.xml'`  (matched via read.xml)
  #     end
  #
  #   end
  def expand_setups!
    setups_map = {}
    [:global, :external, nil].each do |container|
      container_setups = (@__e__setups||{})[container]||{}
      public_actions.each do |action|

        # making sure it will work for both ".format" and "action.format" matchers
        action_formats = formats(action) + formats(action).map {|f| action.to_s + f}

        container_setups.each_pair do |position, setups|

          action_setups = setups.select do |(m)|
            m == :* || m == action ||
              (m.is_a?(Regexp) && action.to_s =~ m) ||
              (m.is_a?(String) && action_formats.include?(m)) ||
              setup_aliases(position, action).include?(m)
          end

          (((setups_map[position]||={})[action]||={})[nil]||=[]).concat action_setups.inject([]) { |f,s|
            # excluding format-related setups
            s.first.is_a?(String) ? f : f << s.last
          }

          formats(action).each do |format|
            (setups_map[position][action][format]||=[]).concat action_setups.inject([]) {|f,s|
              # excluding format-related setups that does not match current format
              s.first.is_a?(String) ?
                (s.first =~ /#{Regexp.escape format}\Z/ ? f << s.last : f) : f << s.last
            }
          end

        end
        
      end
    end
    @__e__expanded_setups = setups_map
  end

  # turning Regexp and * matchers into real action names
  def expand_formats!
    global_formats = (@__e__formats||[]).map {|f| '.' << f.to_s.sub('.', '')}.uniq
    strict_formats = (@__e__formats_for||[]).inject([]) do |u,(m,f)|
      u << [m, f.map {|e| '.' << e.to_s.sub('.', '')}.uniq]
    end

    define_format_helpers(global_formats, strict_formats)

    @__e__expanded_formats = public_actions.inject({}) do |map, action|
      map[action] = global_formats

      action_formats = strict_formats.inject([]) do |formats,(m,f)|
        m == action ||
          (m.is_a?(Regexp) && action.to_s =~ m) ? formats.concat(f) : formats
      end
      map[action] = action_formats if action_formats.any?

      (@__e__disable_formats_for||[]).each do |m|
        map.delete(action) if m == action || (m.is_a?(Regexp) && action.to_s =~ m)
      end

      map
    end
  end

  # defining a handy #format? method for each format.
  # eg. json? for ".json", xml? for ".xml" etc.
  # these methods aimed to replace the `if format == '.json'` redundancy
  #
  # @example
  #
  #   class App < E
  #
  #     format '.json'
  #
  #     def page
  #       # on /page, json? will return nil
  #       # on /page.json, json? will return '.json'
  #     end
  #   end
  #
  def define_format_helpers global_formats, strict_formats
    (all_formats = (global_formats + strict_formats.map {|s| s.last}.flatten).uniq)
    (all_formats = Hash[all_formats.zip(all_formats)]).each_key do |f|
      method_name = '%s?' % f.sub('.', '')
      define_method method_name do
        # Hash searching is a lot faster than String comparison
        all_formats[format]
      end
      private method_name
    end
  end

end
