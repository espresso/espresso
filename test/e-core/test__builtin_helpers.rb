module ECoreTest__BuiltinHelpers
  class App < E

    def get
      [get?, post?].inspect
    end

    def post_post
      [get?, post?].inspect
    end

    def xhr
      [get?, xhr?].inspect
    end
  end

  Spec.new App do
    Testing :request_method do
      get :get
      is([true, nil].inspect).current_body?
      
      post :post
      is([nil, true].inspect).current_body?
    end

    Testing :requested_with do
      get_x :xhr
      is([true, true].inspect).current_body?

      get :xhr
      is([true, nil].inspect).current_body?
    end
  end

end
