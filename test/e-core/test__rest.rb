module ECoreTest__REST

  class RestApp < E

    def index
    end

    def post_edit
    end

    def put_create
    end

    def head_details
    end

    def post_get_verb
    end

    def router_test action
      route action.to_sym
    end
  end

  Spec.new RestApp do

    Ensure "index respond to any Request Method" do
      EspressoFrameworkConstants::HTTP__REQUEST_METHODS.each do |m|
        self.send m.to_s.downcase
        is(last_response).ok?
      end
    end

    Testing 'defined actions responds only to given request method' do
      get :edit
      is(last_response).not_implemented?

      post :edit
      is(last_response).ok?

      get :create
      is(last_response).not_implemented?

      put :create
      is(last_response).ok?

      post :details
      is(last_response).not_implemented?

      head :details
      is(last_response).ok?

      head :edit
      is(last_response).not_implemented?
    end

    It 'uses only first verb as request method' do
      post :get_verb
      is(last_response).ok?

      get :verb
      is(last_response).not_found?
    end

    Ensure 'route works correctly with deverbified actions' do
      get :router_test, :post_edit
      is(RestApp.base_url + '/edit').current_body?

      get :router_test, :edit
      is(RestApp.base_url + '/edit').current_body?
      
      get :router_test, :put_create
      is(RestApp.base_url + '/create').current_body?

      get :router_test, :create
      is(RestApp.base_url + '/create').current_body?
    end

  end
end
