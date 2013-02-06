
if Cfg.db[:type] && Cfg.db[:name]

  values = Cfg.db.values_at(:type, :user, :pass, :host, :name)
  connection_string = '%s://%s:%s@%s/%s' % values

  case Cfg.db[:orm]
  when :ActiveRecord
    ActiveRecord::Base.establish_connection connection_string

  when :DataMapper
    DataMapper.setup :default, connection_string

  when :Sequel
    Sequel.connect connection_string

  end
end
