module EspressoUtils

  def register_extra_engines!
    VIEW__EXTRA_ENGINES.each do |name, info|
      if Object.const_defined?(name)
        Rabl.register! if name == :Rabl

        # This will constantize the template string
        template = info[:template].split('::').reduce(Object){ |cls, c| cls.const_get(c) }

        VIEW__ENGINE_MAPPER[info[:extension]] = template
        VIEW__ENGINE_BY_SYM[name] = template
        VIEW__EXT_BY_ENGINE[template] = info[:extension].dup.freeze
      end
    end
    # redefining method so engines wont be registered multiple times
    def __method__; end
  end
  module_function :register_extra_engines!
end
