require File.expand_path('../config', __FILE__)
Cfg = AppConfig.new

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, Cfg.env)

require Cfg.app_path('database.rb')

App = EspressoApp.new(:automount)
App.controllers_setup do
  view_path 'app/views'
end

App.assets_url 'assets'
App.assets.prepend_path Cfg.assets_path

Dir[Cfg.helpers_path + '*.rb'].each {|file| require file}

[Cfg.models_path, Cfg.controllers_path].each do |path|
  Dir[path + '*.rb'].each do |file|
    require file
    Dir[file.sub(/(\.rb)\Z/, '/*\1')].each {|f| require f}
  end
end

DataMapper.finalize if Cfg.db[:orm] == :DataMapper
