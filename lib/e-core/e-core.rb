class E
  include Rack::Utils
end

class << E

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
