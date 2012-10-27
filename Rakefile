
require 'rubygems'
require 'rake'

task :default => :test

require './test/setup'
::Dir['./test/**/test__*.rb'].each { |f| require f }

namespace :test do
  task :core do
    puts "\n**\nTesting Core ..."
    session = Specular.new
    session.boot { include Sonar }
    session.before do |app|
      if app && ::AppetiteUtils.is_app?(app)
        app.use Rack::Lint
        app(app)
        map(app.base_url)
      end
    end
    session.run /ECoreTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :view do
    puts "\n**\nTesting View API ..."
    session = Specular.new
    session.boot { include Sonar }
    session.before do |app|
      if app && ::AppetiteUtils.is_app?(app)
        app app.mount { view_fullpath ::File.expand_path('../test/helpers/view/templates', __FILE__) }
        map(app.base_url)
        get
      end
    end
    session.run /EViewTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :helpers do
    puts "\n**\nTesting Helpers ..."
    session = Specular.new
    session.boot { include Sonar }
    session.before do |app|
      if app && ::AppetiteUtils.is_app?(app)
        map app.base_url
        app(app)
      end
    end
    session.run /EHelpersTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  task :ipcm do
    puts "\n**\nTesting InterProcess Cache Manager"
    session = Specular.new
    puts session.run /EIPCMTest/, :trace => true
    session.exit_code == 0 || fail
  end
end

task :test => ['test:core', 'test:view', 'test:helpers']

task :overhead do
  require './test/overhead/run'
end
