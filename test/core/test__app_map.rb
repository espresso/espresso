module ECoreTest__AppMap

  class App < E
    map :ctrl_map

    def index

    end

  end

  Spec.new self do

    app EApp.new { map :app_map; mount App }

    get '/app_map/ctrl_map'
    is(last_response.status) == 200

  end
end
