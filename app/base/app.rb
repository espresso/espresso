require File.expand_path('../base/boot', __FILE__)

options = {}
(server = Cfg[:server]) && (options[:server] = server)
(port   = Cfg[:port]  ) && (options[:port  ] = port  )

puts App.urlmap
App.run options
