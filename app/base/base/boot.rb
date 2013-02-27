
require 'bundler/setup'
Bundler.require(:default)

require 'yaml'
require File.expand_path('../config', __FILE__)

Cfg = AppConfig.new

Bundler.require(Cfg.env)

require Cfg.base_path('database.rb')

App = EspressoApp.new :automount do
  
  controllers_setup do
    view_path 'base/views'
    engine(Cfg[:engine]) if Cfg[:engine]
    format(Cfg[:format]) if Cfg[:format]
  end

  assets_url 'assets'
  assets.prepend_path Cfg.assets_path

  if Cfg.dev?
    use Rack::CommonLogger
    use Rack::ShowExceptions
  end
end

[Cfg.helpers_path, Cfg.models_path].each do |path|
  Dir[path + '**/*.rb'].each {|f| require f}
end

%w[**/*_controller.rb **/*_action.rb].each do |matcher|
  Dir[Cfg.controllers_path + matcher].each {|f| require f}
end

DataMapper.finalize if Cfg[:orm] == :DataMapper
