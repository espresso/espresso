module ECoreTest__Helpers
  class RequestMethods < E

    def get
      get?.inspect
    end
    def post_post
      post?.inspect
    end
  end

  Spec.new RequestMethods do
    Testing 'request method helpers' do
      get :get
      is('true').current_body?
      
      post :post
      is('true').current_body?
    end
  end

end
