
if Cfg.db[:type] && Cfg.db[:name]
  values = Cfg.db.values_at(:type, :user, :pass, :host, :name)
  connection_string = '%s://%s:%s@%s/%s' % values
  Sequel.connect connection_string
end
