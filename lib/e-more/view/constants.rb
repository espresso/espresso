module EConstants

  # this map is used to define adhoc renderers like `render_haml` etc.
  VIEW__ENGINE_MAPPER = {}

  # used to validate engine provided by user.
  # we could simply validate by Tilt.const_defined?(user_input + 'Template')
  # but not all engines are registered under Tilt namespace, e.g. Slim, Rabl
  VIEW__ENGINE_BY_SYM = {}

  # Slim and Rabl adapters not shipped with Tilt
  VIEW__EXTRA_ENGINES = {
    Slim: {extension: '.slim', template: 'Slim::Template'},
    Rabl: {extension: '.rabl', template: 'RablTemplate'}
  }
  VIEW__EXTRA_ENGINES.each_key {|e| VIEW__ENGINE_BY_SYM[e] = nil}

  Tilt.mappings.each do |(ext,engines)|
    engines.each do |engine|
      engine_name = engine.to_s.scan(/(\w+)Template/).flatten.first || next
      VIEW__ENGINE_MAPPER['.' + engine_name.downcase] = engine
      VIEW__ENGINE_BY_SYM[engine_name.to_sym] = engine
    end
  end

  # used to determine extension when no explicit extension given via `engine_ext`
  # this will build a map like:
  # {
  #   Tilt::ERBTemplate    => "erb",
  #   Tilt::ErubisTemplate => "erb",
  #   Tilt::HamlTemplate   => "haml",
  #   # etc.
  # }
  VIEW__EXT_BY_ENGINE = Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
    inject({}) {|m,i| i.last.each { |e| m.update e => ('.' + i.first).freeze }; m }

  # making sure adhoc renderers will be defined for extra engines
  # even if they are required after Espresso
  VIEW__EXTRA_ENGINES.each_value do |info|
    VIEW__ENGINE_MAPPER[info[:extension]] = nil
  end

  VIEW__DEFAULT_PATH   = 'view/'.freeze
  VIEW__DEFAULT_ENGINE = [Tilt::ERBTemplate]
  VIEW__DEFAULT_ENGINE_NAME = :ERB
end
