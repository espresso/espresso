require 'rubygems'
require 'bundler/setup'
Bundler.require

App = EspressoApp.new
require File.expand_path('../config', __FILE__)
Cfg = AppConfig.new(App, ENV['RACK_ENV'])
App.assets_url 'assets'
App.assets.prepend_path Cfg.assets_path
  
Dir[Cfg.controllers_path('**/*.rb')].each {|file| require file}
Dir[Cfg.models_path('**/*.rb')].each {|file| require file}

App.controllers_setup do
  view_path 'app/views'
end
App.automount!
puts App.urlmap
