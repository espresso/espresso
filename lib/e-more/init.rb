module EspressoConstants

  VIEW__ENGINE_BY_EXT, VIEW__ENGINE_BY_SYM = {}, {}
  
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
  # Rabl adapter not shipped with Tilt,
  # so adding Rabl to map to be sure adhoc methods are defined at loadtime
  VIEW__ENGINE_BY_EXT['.rabl'] = nil unless VIEW__ENGINE_BY_EXT.has_key?('.rabl')
  VIEW__ENGINE_BY_SYM[:Rabl]   = nil unless VIEW__ENGINE_BY_SYM.has_key?(:Rabl)

  # Slim adapter not shipped with Tilt,
  # so adding Slim to map to be sure adhoc methods are defined at loadtime
  VIEW__ENGINE_BY_EXT['.slim'] = nil unless VIEW__ENGINE_BY_EXT.has_key?('.slim')
  VIEW__ENGINE_BY_SYM[:Slim]   = nil unless VIEW__ENGINE_BY_SYM.has_key?(:Slim)

  VIEW__EXT_BY_ENGINE = Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
    inject({}) { |m, i| i.last.each { |e| m.update e => ('.' + i.first).freeze }; m }
  
  VIEW__DEFAULT_PATH   = 'view/'.freeze
  VIEW__DEFAULT_ENGINE = [Tilt::ERBTemplate]

end
