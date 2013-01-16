module ECoreTest__Helpers
  class RequestMethods < E

    def get
      get?.inspect
    end
    def post
      post?.inspect
    end
    def put
      put?.inspect
    end
  end

  Spec.new RequestMethods do
    get :get
    is('true').current_body?
    post :get
    is('false').current_body?
    
    post :post
    is('true').current_body?
    get :post
    is('false').current_body?

    put :put
    is('true').current_body?
    post :put
    is('false').current_body?
  end

end
