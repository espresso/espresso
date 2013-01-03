$:.unshift File.expand_path('../../../../lib', __FILE__)
require 'e'

class App < E
  map :/
  before do
    clear_cache! if params[:clear_cache]
    clear_compiler! if params[:clear_compiler]
  end

  def cache_test body
    cache { body }
  end

  def compiler_test body
    File.open(app.root + 'view/compiler_test.erb', 'w') { |f| f << body }
    render
  end
end
run EApp.new {
  mount App
  compiler_pool Hash.new
  pids do
    Dir[File.expand_path('../tmp/pids/*.pid', __FILE__)].map { |f| File.read f }
  end
  use Rack::ShowExceptions
}
