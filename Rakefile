require 'rake'
require 'bundler/gem_helper'
require './test/setup'
Dir['./test/**/test__*.rb'].each { |f| require f }

namespace :test do

  def run regex, unit
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
      if tested_app && EUtils.is_app?(tested_app)
        tested_app.use Rack::Lint
        if ['e-more', :ViewAPI].include?(unit)
          app tested_app.mount {
            view_fullpath File.expand_path('../test/e-more/view/templates', __FILE__)
          }
        else
          app tested_app.mount
        end
        map tested_app.base_url
      end
    end
    session
  end

  task :core do
    run(/ECoreTest/, "e-core")
  end

  task :more do
    run(/EMoreTest/, "e-more")
  end

  task :view do
    run(/EMoreTest__View/, :ViewAPI)
  end
end

task test: ['test:core', 'test:more']
task :overhead do
  require './test/overhead/run'
end
task default: :test

Bundler::GemHelper.install_tasks
