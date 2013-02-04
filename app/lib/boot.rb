require 'rubygems'
require 'bundler/setup'
Bundler.require

App = EspressoApp.new :automount
App.controllers_setup do
  view_path 'lib/view'
end

require File.expand_path('../config', __FILE__)
Cfg = AppConfig.new(App)
