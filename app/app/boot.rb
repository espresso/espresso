require 'rubygems'
require 'bundler/setup'
Bundler.require

App = EspressoApp.new
require File.expand_path('../config', __FILE__)
Cfg = AppConfig.new(App)
App.assets_url 'assets'
App.assets.prepend_path Cfg.path.assets
  
Dir[Cfg.path.controllers + '**/*.rb'].each {|file| require file}

App.controllers_setup do
  view_path 'lib/view'
end
App.automount!
puts App.urlmap
