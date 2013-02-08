class AppConfig

  include EspressoUtils

  DEFAULT_ENV = E__ENVIRONMENTS.first

  attr_reader :path, :db, :env

  def initialize
    env = ENV['RACK_ENV'] || DEFAULT_ENV
    env = env.to_s.to_sym
    E__ENVIRONMENTS.include?(env) ||
      raise("#{env} environment not supported. Please use one of #{E__ENVIRONMENTS.join ', '}")

    set_paths Dir.pwd
    set_env env
    load_config
    load_db_config
    @opted_config = {}
  end

  def self.paths
    {
      :root   => [:config, :base, :public, :var, :tmp],
      :base   => [:models, :views, :controllers, :helpers, :specs],
      :var    => [:pid, :log],
      :public => [:assets],
    }
  end

  paths.each_value do |paths|
    paths.each do |p|
      define_method '%s_path' % p do |*chunks|
        File.join(@path[p], *chunks)
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
    path = {:root => (root.to_s + '/').gsub(/\/+/, '/')}
    self.class.paths.each_pair do |ns,paths|
      paths.each do |p|
        path[p] = path[ns] + p.to_s + '/'
      end
    end
    @path = indifferent_params(path).freeze
  end

  def set_env env
    @env = env ? env.to_s.downcase.to_sym : DEFAULT_ENV
  end

  def load_config
    @config = load_file 'config.yml'
  end

  def load_db_config
    @db = load_file'database.yml'
  end

  def load_file file
    path = config_path(file)
    data = File.file?(path) ? YAML.load(File.read(path)) : nil
    return indifferent_params(data[@env] || data[@env.to_s]) if data.is_a?(Hash)
    warn "#{file} does not exists"
    {}
  end

end
