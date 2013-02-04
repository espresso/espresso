class AppConfig

  attr_reader :path, :env, :db

  def initialize app
    path = {'root' => app.root}
    %w[config app public var tmp].each do |d|
      path[d] = app.root + d + '/'
    end
    %w[models views controllers helper spec].each do |d|
      path[d] = app.root + 'app/' + d + '/'
    end
    %w[pid log].each do |d|
      path[d] = app.root + 'var/' + d + '/'
    end
    path['assets'] = path['public'] + 'assets/'

    @path = Struct.new(*path.keys.map(&:to_sym)).new(*path.values)

    @env = (ENV['RACK_ENV'] || 'dev').to_sym

    yaml = YAML.load(File.read(@path.config + 'config.yml')).freeze
    @config = EspressoUtils.indifferent_params(yaml[@env] || yaml[@env.to_s])
  
    yaml = YAML.load(File.read(@path.config + 'database.yml')).freeze
    if config = yaml[@env] || yaml[@env.to_s]
      @db = Struct.new(*config.keys.map(&:to_sym)).new(*config.values)
    end
  end

  def method_missing meth
    @config[meth]
  end

  def dev_env?
    env == :dev
  end

  def prod_env?
    env == :prod
  end

  def test_env?
    env == :test
  end
  
end
