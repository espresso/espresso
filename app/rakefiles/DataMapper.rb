
namespace :db do

  models = ObjectSpace.each_object(Class).select do |c|
    c.ancestors.include?(DataMapper::Resource)
  end
  {
    migrate: 'Migrating %s. ACHTUNG! this is a destructive action!',
    upgrade: 'Upgrading %s',
  }.each_pair do |t,d|
    namespace t do
      meth = 'auto_%s!' % t
      desc d % 'ALL Models'
      task :all do
        puts '%s...' % t
        models.each do |m|
          puts '  %s' % m
          m.send(meth)
        end
      end
      models.each do |m|
        desc d % m
        task m do
          puts '%s...' % t
          puts '  %s'  % m
          m.send(meth)
        end
      end
    end
  end

end
