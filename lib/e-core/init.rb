class E
  include Rack::Utils
  include EspressoFrameworkConstants
end

class << E
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils

  def include mdl
    super
    (@__e__included_actions ||= []).concat mdl.public_instance_methods(false)
  end

  def define_setup_method meth
    (class << self; self end).class_exec do
      define_method meth do |*args, &proc|
        add_setup(:a) { self.send meth, *args, &proc }
      end
    end
  end

end

class EspressoFrameworkRewriter
  include Rack::Utils
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
end

class EspressoApp
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
end

class EApp < EspressoApp
  def initialize(*)
    warn "\n--- Warning: EApp will be deprecated soon. Please use EspressoApp instead ---\n"
    super
  end
end
