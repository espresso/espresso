class << E

  # set the callbacks to be executed before/after given(or all) actions.
  #
  # @note can be set by both controller and slice.
  #       so, if there are N callbacks set by controller and M set by slice,
  #       N + M callbacks will be executed.
  #
  # @note callbacks will be executed in the order was added.
  #       to change the calling order, use :priority option.
  #       the callback with highest priority will run first.
  #
  # @example defining the callback, to be executed before all actions
  #      before do
  #        puts "will be executed before each action"
  #      end
  #
  # @example  making sure this will run before any other hooks by setting priority to 1000,
  #           (with condition there are no hooks with higher priority)
  #      before :priority => 1000 do
  #        # ...
  #      end
  #
  # @example defining the callback to be executed only before :index
  #      setup :index do
  #        before { "some logic" }
  #      end
  #
  # @example defining the callback to be executed after :post_login and :put_edit actions
  #      setup :post_login, :put_edit do
  #        after { "some logic" }
  #      end
  #
  # @param [Proc] proc
  def before opts = {}, &proc
    add_hook :a, opts, &proc
  end

  # (see #before)
  def after opts = {}, &proc
    add_hook :z, opts, &proc
  end

  def around opts = {}, &proc
    add_hook :m, opts, &proc
  end

  def hooks? position, action = nil
    initialize_hooks position
    @sorted_hooks[[position,action]] ||= sort_hooks(position, action)
  end

  private
  def initialize_hooks position
    (@sorted_hooks ||= {})
    (@hooks ||= {})[position] ||= {}
  end

  # sorting hooks in DESCENDING order, so the ones with highest priority will run first
  def sort_hooks position, action = nil
    ((@hooks[position][:*] || []) + (@hooks[position][action] || [])).sort do |a,b|
      b.first <=> a.first
    end.map { |h| h.last }
  end

  def add_hook position, opts = {}, &proc
    return if locked? || proc.nil?
    initialize_hooks position
    method = proc_to_method(:hooks, position, *setup__actions, &proc)
    setup__actions.each do |a|
      (@hooks[position][a] ||= []) << [opts[:priority].to_i, method]
    end
  end

end

class E
  def invoke_before_filters
    (self.class.hooks?(:a, action_with_format)||[]).each { |m| self.send m }
  end

  def invoke_after_filters
    (self.class.hooks?(:z, action_with_format)||[]).each { |m| self.send m }
  end
end
