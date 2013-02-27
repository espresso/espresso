module ECoreTest__Files

  class App < E

    def fs
      send_files params[:path]
    end

  end

  Spec.new App do
    Testing do
      path = File.expand_path('..', __FILE__)
      get :fs, :path => path

      Dir[path + '/*.rb'].each do |file|
        does(%r[app/fs/#{File.basename(__FILE__)}]).match_body?
      end
    end
  end
end
