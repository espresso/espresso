class << E

  # @api semi-public
  #
  # remap served root(s) by prepend given path to controller's root and canonical paths
  #
  # @note Important: all actions should be defined before re-mapping occurring
  #
  def remap! root, *canonicals
    return if locked?
    base_url = root.to_s + '/' + base_url()
    new_canonicals = [] + canonicals
    canonicals().each do |ec|
      # each existing canonical should be prepended with new root
      new_canonicals << base_url + '/' + ec.to_s
      # as well as with each given canonical
      canonicals.each do |gc|
        new_canonicals << gc.to_s + '/' + ec.to_s
      end
    end
    map base_url, *new_canonicals
  end

  def global_setup! &setup
    return unless setup
    @global_setup = true
    setup.arity == 1 ?
        self.class_exec(self, &setup) :
        self.class_exec(&setup)
    setup!
    @global_setup = false
  end

  def global_setup?
    @global_setup
  end

  def session(*)
    raise 'Please use `%s` at app level only' % __method__
  end

  def rewrite(*)
    raise 'Please use `%s` at app level only' % __method__
  end
  alias rewrite_rule rewrite

  private

  # instance_exec at runtime is expensive enough,
  # so compiling procs into methods at load time.
  def proc_to_method *chunks, &proc
    chunks += [self.to_s, proc.to_s]
    name = ('__appetite__e__%s__' %
        chunks.map { |s| s.to_s }.join('_').gsub(/[^\w|\d]/, '_')).to_sym
    define_method name, &proc
    name
  end

end
