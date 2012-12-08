require File.expand_path('../boot', __FILE__)
Bundler.require :default

# running Espresso app that was built inside ./boot.rb
ECalendarApp.run server: :Reel, Port: 4040
