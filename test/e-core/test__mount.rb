module ECoreTest__Mount
  module ByArgs
    class App1 < E
      class App2 < E
      end
    end

    Spec.new self do
      eapp = EApp.new
      eapp.mount App1, App1::App2, '/app'
      app eapp
      map '/app'

      Ensure 'both controllers mounted' do
        get :app1
        is(last_response).ok?
        
        get :app2
        is(last_response).ok?
      end

    end
  end

  module ByModule
    class App1 < E
      class App2 < E
      end
    end

    Spec.new self do
      eapp = EApp.new
      eapp.mount ByModule
      app eapp

      Ensure 'all controllers mounted' do
        get :app1
        is(last_response).ok?
        
        get :app2
        is(last_response).ok?
      end

    end
  end

  module ByClass
    class App1 < E
      class App2 < E
      end
    end

    Spec.new self do
      eapp = EApp.new
      eapp.mount ByClass
      app eapp

      Ensure 'all controllers mounted' do
        get :app1
        is(last_response).ok?
        
        get :app2
        is(last_response).ok?
      end

    end
  end

  module ByRegexp
    class TopApp < E
      map :regexp1
      class NestedApp < E
        map :regexp2
      end
    end

    Spec.new self do
      eapp = EApp.new
      eapp.mount /ByRegexp/
      app eapp

      Ensure 'all controllers mounted' do
        get :regexp1
        is(last_response).ok?
        
        get :regexp2
        is(last_response).ok?
      end

    end
  end

end
