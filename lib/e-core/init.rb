class E
  include Rack::Utils
  include EspressoFrameworkConstants
end

class << E
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils

  def include mdl
    super
    (@included_actions ||= []).concat mdl.public_instance_methods(false)
  end

  # creates a generic setup method for various
  def define_setup_method meth
    (class << self; self end).class_exec do
      define_method meth do |*args, &proc|
        add_setup(:a) { self.send meth, *args, &proc }
      end
    end
  end

  # creates a reader method + @__e__-type instance variable
  def e_attribute(var, block=nil)
    if block
      #TODO
    else
      self.class_eval(%Q{
        def #{var}
          @__e__#{var}
        end

        def #{var}=(value)
          @__e__#{var} = value
        end
      })
    end
  end

  def e_attributes(*args)
    Array(args).each do |m|
      e_attribute m
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

def EApp
  warn "EApp will be deprecated. Please use EspressoApp instead."
  EspressoApp
end
