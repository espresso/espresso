module ECoreTest__ActionName
  class App < E

    def index
    end
    
    def put_index
    end

    def foo
    end

    def post_foo
    end

    def delete_foo
    end

    after do
      response.body = [[rq.request_method, action, action_name].join("|")]
    end
  end

  Spec.new App do

    get
    is('GET|index|index').current_body?

    put
    is('PUT|put_index|index').current_body?

    get :foo
    is('GET|foo|foo').current_body?
    
    post :foo
    is('POST|post_foo|foo').current_body?
    
    delete :foo
    is('DELETE|delete_foo|foo').current_body?
  end
end
