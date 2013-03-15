module EspressoConstants

  VIEW__ENGINE_BY_EXT, VIEW__ENGINE_BY_SYM = {}, {}
  
  if Object.const_defined?(:Slim)
    Tilt.register 'slim', Slim::Template
  end

  if Object.const_defined?(:Rabl)
    Rabl.register!
  end

  Tilt.mappings.each do |m|
    m.last.each do |engine|
      engine_name = engine.name.split('::').last.sub(/Template\Z/, '')
      engine_name = engine.name.split('::').first if engine_name.empty?
      next if engine_name.empty?
      VIEW__ENGINE_BY_EXT['.' + engine_name.downcase] = engine
      VIEW__ENGINE_BY_SYM[engine_name.to_sym] = engine
    end
  end

  VIEW__EXT_BY_ENGINE = Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
    inject({}) { |m, i| i.last.each { |e| m.update e => ('.' + i.first).freeze }; m }
  
  VIEW__DEFAULT_PATH   = 'view/'.freeze
  VIEW__DEFAULT_ENGINE = [Tilt::ERBTemplate]

  VIEW__EXTRA_ENGINES = {Slim: {extension: '.slim', template: 'Slim::Template'},
                         Rabl: {extension: '.rabl', template: 'RablTemplate'}}

end

module EspressoUtils
  def register_extra_engines!
    VIEW__EXTRA_ENGINES.each do |name, info|
      if Object.const_defined?(name)
        Rabl.register! if name == :Rabl

        # This will constantize the template string
        template = info[:template].split('::').reduce(Object){ |cls, c| cls.const_get(c) }

        VIEW__ENGINE_BY_EXT[info[:extension]] = template
        VIEW__ENGINE_BY_SYM[name] = template
        VIEW__EXT_BY_ENGINE[template] = info[:extension].dup.freeze
      end
    end
    def __method__; end
  end
  module_function :register_extra_engines!
end
