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

end
