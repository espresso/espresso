require 'rubygems'
require 'rake'

require './test/setup'
Dir['./test/**/test__*.rb'].each { |f| require f }

namespace :test do

  def run_test regex, unit
    puts "\n***\nTesting #{unit} ..."
    session = session(unit)
    session.run regex, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code == 0 || fail
  end

  def session unit
    session = Specular.new
    session.boot do
      include Sonar
      include HttpSpecHelper
    end
    session.before do |tested_app|
      if tested_app && EspressoFrameworkUtils.is_app?(tested_app)
        tested_app.use Rack::Lint
        if ['e-more', :ViewAPI].include?(unit)
          app tested_app.mount { view_fullpath File.expand_path('../test/e-more/view/templates', __FILE__) }
        else
          app tested_app.mount
        end
        map tested_app.base_url
      end
    end
    session
  end

  task :core do
    run_test(/ECoreTest/, "e-core")
  end

  task :more do
    run_test(/EMoreTest/, "e-more")
  end

  task :view do
    run_test(/EMoreTest__View/, :ViewAPI)
  end

  task :cache do
    run_test(/EMoreTest__Cache/, :Cache)
  end

  task :crud do
    run_test(/EMoreTest__CRUD/, :CRUD)
  end

  task :assets do
    run_test(/EMoreTest__Assets/, :Assets)
  end

  task :ipcm do
    run_test(/EIPCMTest/, :IPCM)
  end
end

task :test => ['test:core', 'test:more']
task :overhead do
  require './test/overhead/run'
end
task :default => :test
