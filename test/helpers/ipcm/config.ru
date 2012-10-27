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
    File.open(app_root + 'view/compiler_test.erb', 'w') { |f| f << body }
    render '' => true
  end

end
app = EApp.new do
  mount App
  use Rack::ShowExceptions
  pids do
    Dir[File.expand_path('../tmp/pids/*.pid', __FILE__)].map { |f| File.read f }
  end
end
run app
