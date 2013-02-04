require File.expand_path('../app/boot', __FILE__)

options = {}
(server = Cfg.server) && (options[:server] = server)
(port   = Cfg.port  ) && (options[:port  ] = port  )
App.run options
