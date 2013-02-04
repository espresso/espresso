require File.expand_path('../lib/boot', __FILE__)

opts    = {}
(server = Cfg.server) && (opts[:server] = server)
(port   = Cfg.server) && (opts[:port  ] = port  )
App.run opts
