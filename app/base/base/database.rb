
if Cfg.db[:type] && Cfg.db[:name]

  values = Cfg.db.values_at(:type, :user, :pass, :host, :name)
  connection_string = '%s://%s:%s@%s/%s' % values

  case Cfg[:orm]
  when 'activerecord'
    ActiveRecord::Base.establish_connection connection_string

  when 'data_mapper'
    DataMapper.setup :default, connection_string

  when 'sequel'
    Sequel.connect connection_string

  end
end
