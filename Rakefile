require 'rubygems'
require 'rake'

require './test/setup'
Dir['./test/**/test__*.rb'].each { |f| require f }

namespace :test do

  session = Specular.new
  session.boot { include Sonar }
  session.before do |app|
    include BddApi
    include HttpSpecHelper
    if app && EspressoFrameworkUtils.is_app?(app)
      app.use Rack::Lint
      app(app.mount)
      map(app.base_url)
    end
  end

  task :core do
    puts "\n**\nTesting Core ..."
    session.run /ECoreTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :cache do
    puts "\n**\nTesting Cache ..."
    session.run /EMoreTest__Cache/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :crud do
    puts "\n**\nTesting CRUD ..."
    session.run /EMoreTest__CRUD/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :ipcm do
    puts "\n**\nTesting InterProcess Cache Manager"
    puts session.run /EMoreTest__IPCM/, :trace => true
    session.exit_code == 0 || fail
  end

  task :view do
    puts "\n**\nTesting View API ..."
    session = Specular.new
    session.boot { include Sonar }
    session.before do |app|
      if app && EspressoFrameworkUtils.is_app?(app)
        app app.mount { view_fullpath File.expand_path('../test/e-more/view/templates', __FILE__) }
        map(app.base_url)
        get
      end
    end
    session.run /EMoreTest__View/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end
end

task :test => ['test:core', 'test:view', 'test:crud', 'test:cache']
task :overhead do
  require './test/overhead/run'
end
task :default => :test
