# setting up various aspects of the controller.
# @note:  getters should NOT set instance variables,
#         cause instance variable are frozen after controller is mounted.
#
#         so this will raise an error at runtime:
#         def canonicals
#           @canonicals ||= []
#         end
#
#         and this will work:
#         def canonicals
#           @canonicals || []
#         end
class << E

  # setting controller's base URL
  #
  # if multiple paths provided, first path is treated as root,
  # and other ones are treated as canonical routes.
  # canonical routes allow controller to serve multiple roots.
  #
  def map *paths
    return if mounted?
    @base_url   = rootify_url(paths.shift.to_s).freeze
    @canonicals = paths.map { |p| rootify_url(p.to_s) }.freeze
  end

  def base_url
    @base_url ||= ('/' << self.name.to_s.split('::').last.
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase).freeze
  end
  alias baseurl base_url

  def canonicals
    @canonicals || []
  end

  # add/update a path rule
  #
  # @note default rules
  #    - "__"   (2 underscores) => "-" (dash)
  #    - "___"  (3 underscores) => "/" (slash)
  #    - "____" (4 underscores) => "." (period)
  #
  # @example
  #    path_rule  "__d__" => "-"
  #
  #    def some__d__action
  #      # will resolve to some-action
  #    end
  #
  # @example
  #    path_rule  "!" => ".html"
  #
  #    def some_action!
  #      # will resolve to some_action.html
  #    end
  #
  # @example
  #    path_rule  /_j$/ => ".json"
  #
  #    def some_action_j
  #      # will resolve to some_action.json
  #    end
  #
  def path_rule from, to
    return if mounted?
    (@path_rules ||= Hash[E__PATH_RULES]).update from => to
  end

  def path_rules
    return @sorted_path_rules if @sorted_path_rules
    rules = (@path_rules || E__PATH_RULES).inject({}) do |f,(from, to)|
      from = /#{from}/ unless from.is_a?(Regexp)
      f.merge from => to
    end
    @sorted_path_rules = Hash[rules.sort {|a,b| b.first.source.size <=> a.first.source.size}]
  end

  # allow to set routes directly, without relying on path rules.
  #
  # @example make :bar method to serve /bar, /some/url and /some/another/url
  #   def bar
  #     # ...
  #   end
  #
  #   action_alias 'some/url', :bar
  #   action_alias 'some/another/url', :bar
  #
  # @example make private method :foo to serve /some/url
  #
  #   action_alias 'some/url', :foo
  #
  #   private
  #   def foo
  #     # ...
  #   end
  def action_alias url, action
    return if mounted?
    ((@action_aliases ||= {})[action]||=[]) << url
  end

  def action_aliases
    @action_aliases || {}
  end

  # automatically setting URL extension and Content-Type.
  # this method will set formats for all actions.
  #
  # @example
  #
  #   class App < E
  #
  #     format '.html', '.xml', '.etc'
  #
  #   end
  #
  def format *formats
    return if mounted?
    (@formats ||= []).concat formats
  end

  # setting format(s) for specific action.
  # first argument is the action name or a Regex matching multiple action names.
  # consequent arguments are the formats to be served.
  #
  # @example make :page action to serve .html format
  #
  #   class App < E
  #
  #     format_for :page, '.html'
  #
  #   end
  #
  # @example make :page action to serve .html and .xml formats
  #
  #   class App < E
  #
  #     format_for :page, '.html', '.xml'
  #
  #   end
  #
  # @example make actions that match /api/ to serve .json format
  #
  #   class App < E
  #
  #     format_for /api/, '.json'
  #
  #   end
  #
  # @example make :api action to serve .json and .xml formats
  #               and any other actions to serve .html format
  #
  #   class App < E
  #
  #     format_for :api, '.json', '.xml'
  #     format '.html'
  #
  #   end
  #
  def format_for matcher, *formats
    return if mounted?
    (@formats_for ||= []) << [matcher, formats]
  end

  # allow to disable format for specific action(s).
  # any number of arguments accepted(zero arguments will have no effect).
  #
  # @example  all actions will serve .xml format,
  #           except :read action, which wont serve any format
  #
  #   format '.xml'
  #   disable_format_for :read
  #
  # @example  actions matching /api/ wont serve any formats
  #
  #   disable_format_for /api/
  #
  def disable_format_for *matchers
    return if mounted?
    (@disable_formats_for ||= []).concat matchers
  end

  def formats action
    (@expanded_formats || {})[action] || []
  end

  # add setups to be executed before/after given(or all) actions.
  #
  # @note setups will be executed in the order they was added
  # @note #before, #setup and #on are aliases
  #
  # @example setup to be executed before any action
  #      setup do
  #        # ...
  #      end
  #
  # @example defining the setup to be executed only before :index
  #      before :index do
  #         # ...
  #      end
  #
  # @example defining a setup to be executed after :post_login and :put_edit actions
  #      after :post_login, :put_edit do
  #        # ...
  #      end
  #
  # @example  running a setup before :blue action
  #           as well as before actions matching "red"
  #      before :blue, /red/ do
  #        # ...
  #      end
  #
  # @example running a  setup for any action on .json format
  #      on '.json' do
  #        # ...
  #      end
  #
  # @example running a  setup for :api action on .json format
  #      on 'api.json' do
  #        # ...
  #      end
  #
  def before *matchers, &proc
    add_setup :a, *matchers, &proc
  end
  alias on    before
  alias setup before

  # (see #before)
  def after *matchers, &proc
    add_setup :z, *matchers, &proc
  end

  def add_setup position, *matchers, &proc
    return if mounted?
    @setups  ||= {}
    method   = proc_to_method(:setups, position, *matchers, &proc)
    matchers = [:*] if matchers.empty?
    matchers.each do |matcher|
      (@setups[position] ||= []) << [matcher, method]
    end
  end
  private :add_setup



  def setups position, action, format
    return [] unless (s = @expanded_setups) && (s = s[position]) && (s = s[action])
    s[format] || []
  end

  # add Rack middleware to chain
  def use ware, *args, &proc
    return if mounted?
    (@middleware ||= []).none? {|w| w.first == ware} && @middleware << [ware, args, proc]
  end

  def middleware
    @middleware || []
  end

  # define a block to be executed on errors.
  # the block should return a [String] error message.
  #
  # multiple error codes accepted.
  # if no error codes given, the block will be effective for any error type.
  #
  # @example handle 404 errors:
  #    class App < E
  #
  #      error 404 do |error_message|
  #        "Some weird error occurred: #{ error_message }"
  #      end
  #    end
  #
  # @param [Integer] code
  # @param [Proc] proc
  #
  def error *error_codes, &proc
    return if mounted?
    proc || raise(ArgumentError, 'Error handlers require a block')
    error_codes.any? || error_codes = [:*]
    meth = proc_to_method(:error_handlers, *error_codes, &proc)
    error_codes.each {|c| (@error_handlers ||= {})[c] = [meth, proc.arity]}
  end

  def error_handler error_code
    ((@error_handlers || {}).find {|k,v| error_code == k} || []).last
  end

end
