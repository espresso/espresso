module ECoreTest__Files

  class App < E

    def index
      send_files params[:path]
    end

  end

  Spec.new App do

    path = File.expand_path('..', __FILE__)
    get :path => path

    Dir[path + '/*.rb'].each do |file|
      expect(last_response.body) =~ /app\/#{File.basename(__FILE__)}/
    end

  end
end
