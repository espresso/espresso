require 'rubygems'
require 'rake'

require './test/setup'
Dir['./test/**/test__*.rb'].each { |f| require f }

namespace :test do

  def run_test(regex, message, session)
    puts "\n**\n#{message} ..."
    session.run regex, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  def default_session
    session = Specular.new
    session.boot do
      include Sonar
      include HttpSpecHelper
    end
    session.before do |app|
      if app && EspressoFrameworkUtils.is_app?(app)
        app.use Rack::Lint
        app(app)
        map(app.base_url)
      end
    end
    session
  end

  task :core do
    run_test(/ECoreTest/, "Testing Core", default_session)
  end

  task :cache do
    run_test(/EMoreTest__Cache/, "Testing Cache", default_session)
  end

  task :crud do
    run_test(/EMoreTest__CRUD/, "Testing CRUD", default_session)
  end

  task :assets do
    run_test(/EMoreTest__Assets/, "Testing Assets", default_session)
  end

  task :ipcm do
    run_test(/EMoreTest__IPCM/, "Testing InterProcess Cache Manager", default_session)
  end

  task :view do
    session = Specular.new
    session.boot { include Sonar }
    session.before do |app|
      if app && EspressoFrameworkUtils.is_app?(app)
        app app.mount { view_fullpath File.expand_path('../test/e-more/view/templates', __FILE__) }
        map(app.base_url)
        get
      end
    end
    run_test(/EMoreTest__View/, "Testing View API", session)
  end
end

task :test => ['test:core', 'test:view', 'test:crud', 'test:cache']
task :overhead do
  require './test/overhead/run'
end
task :default => :test
