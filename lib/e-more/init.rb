module EspressoFrameworkConstants

  VIEW__ENGINE_BY_EXT, VIEW__ENGINE_BY_SYM = {}, {}
  
  Tilt.mappings.each do |m|
    m.last.each do |engine|
      engine_name = engine.name.split('::').last.sub(/Template\Z/, '')
      next if engine_name.empty?
      VIEW__ENGINE_BY_EXT['.' + engine_name.downcase] = engine
      VIEW__ENGINE_BY_SYM[engine_name.to_sym] = engine
    end
  end
  # Slim adapter not shipped with Tilt,
  # so adding Slim to map to be sure adhoc methods are defined at loadtime
  VIEW__ENGINE_BY_EXT['.slim'] = nil unless VIEW__ENGINE_BY_EXT.has_key?('.slim')

  VIEW__EXT_BY_ENGINE = Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
    inject({}) { |m, i| i.last.each { |e| m.update e => ('.' + i.first).freeze }; m }
  
  VIEW__DEFAULT_PATH   = 'view/'.freeze
  VIEW__DEFAULT_ENGINE = [Tilt::ERBTemplate]

end

module EspressoFrameworkUtils
  def register_slim_engine!
    if Object.const_defined?(:Slim)
      VIEW__ENGINE_BY_EXT['.slim'] = Slim::Template
      VIEW__ENGINE_BY_SYM[:Slim]  = Slim::Template
      VIEW__EXT_BY_ENGINE[Slim::Template] = '.slim'.freeze
    end
    def __method__; end
  end
  module_function :register_slim_engine!
end
