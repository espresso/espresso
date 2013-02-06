class AppConfig

  DEFAULT_ENV = 'dev'.freeze
  ENVIRONMENTS = [:dev, :test, :prod].freeze

  attr_reader :path, :db, :env

  def initialize
    env = ENV['RACK_ENV'] || DEFAULT_ENV
    env = env.to_sym unless env.is_a?(Symbol)
    ENVIRONMENTS.include?(env) ||
      raise("#{env} environment not supported")

    set_paths Dir.pwd
    set_env env
    load_config
    load_db_config
    @opted_config = {}
  end

  def self.paths
    {
      :root   => [:config, :app, :public, :var, :tmp],
      :app    => [:models, :views, :controllers, :helpers, :specs],
      :var    => [:pid, :log],
      :public => [:assets],
    }
  end

  paths.each_value do |paths|
    paths.each do |p|
      define_method '%s_path' % p do |*chunks|
        File.join(@path[p],  *chunks)
      end
    end
  end
  alias view_path views_path

  def [] config
    @config[config] || @opted_config[config]
  end

  def []= key, val
    @opted_config[key] = val
  end

  def dev?
    env == :dev
  end

  def prod?
    env == :prod
  end

  def test?
    env == :test
  end

  private

  def set_paths root
    path = {:root => root}
    self.class.paths.each_pair do |ns,paths|
      paths.each do |p|
        path[p] = path[ns] + p.to_s + '/'
      end
    end
    @path = EspressoUtils.indifferent_params(path).freeze
  end

  def set_env env
    @env = env ? env.to_s.downcase.to_sym : DEFAULT_ENV
  end

  def load_config
    yaml    = YAML.load(File.read(config_path 'config.yml'))
    @config = EspressoUtils.indifferent_params(yaml[@env] || yaml[@env.to_s] || {})
  end

  def load_db_config
    yaml = YAML.load(File.read(config_path 'database.yml'))
    @db  = EspressoUtils.indifferent_params(yaml[@env] || yaml[@env.to_s] || {})
  end

end
