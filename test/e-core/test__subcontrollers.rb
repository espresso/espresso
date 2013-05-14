module ECoreTest__Subcontrollers

  class API < E
    map :api
    format '.xml'

    def foo
      action_with_format
    end

    def index
      'API#index' + format.to_s
    end
  end

  class App < E
    mount_controller API

    def index
      'App#index'
    end
  end

  Spec.new App do
    
    get
    is('App#index').ok_body?
    
    get 'api'
    is('API#index').ok_body?
    
    get 'api/index'
    is('API#index').ok_body?
    
    get 'api.xml'
    is('API#index.xml').ok_body?
    
    get 'api/foo'
    is('foo').ok_body?

    get 'api/foo.xml'
    is('foo.xml').ok_body?
  end

end
