class E
  include Rack::Utils
  include EspressoFrameworkConstants
end

class << E
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils

  def define_setup_method meth
    (class << self; self end).class_exec do
      define_method meth do |*args, &proc|
        add_setup(:a) { self.send meth, *args, &proc }
      end
    end
  end
end

class EApp
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
end

class Module
  def mount *roots, &setup
    EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end