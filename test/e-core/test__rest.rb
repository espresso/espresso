module ECoreTest__REST

  class RestApp < E

    def index
    end

    def post_index
    end

    def foo
    end

    def get_foo
    end

    def post_foo
    end

    def post_override
    end
    def delete_override
    end
    def override
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

    after /index/, /foo/, /override/ do
      response.body = [[rq.request_method, action].join("|")]
    end

  end

  Spec.new RestApp do

    Ensure "index respond only to GET" do
      get
      is(last_response).ok?

      post
      is(last_response).ok?

      put
      is(last_response).not_implemented?
    end

    Ensure 'defined actions responds only to given request method' do
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

    Ensure 'route works correctly with deRESTified actions' do
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
