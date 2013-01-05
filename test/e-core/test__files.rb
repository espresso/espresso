module ECoreTest__Files

  class App < E

    def index
      send_files params[:path]
    end

  end

  Spec.new App do
    Testing do
      path = File.expand_path('..', __FILE__)
      get :path => path

      Dir[path + '/*.rb'].each do |file|
        does(/app\/#{File.basename(__FILE__)}/).match_body?
      end
    end
  end
end
