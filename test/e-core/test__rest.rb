module ECoreTest__REST

  class RestApp < E

    def index
    end

    def foo
    end

    def post_foo
    end

    def delete_foo
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

    after /index/, /foo/ do
      response.body = [[rq.request_method, action].join("|")]
    end

  end

  Spec.new RestApp do

    Ensure "verbless actions respond to any Request Method" do
      EConstants::HTTP__REQUEST_METHODS.each do |m|
        self.send m.to_s.downcase
        is(last_response).ok?
        is('%s|index' % m).current_body? unless m == 'HEAD'
      end
    end

    Ensure 'verbified actions has priority over verbless ones' do
      get :foo
      is('GET|foo').current_body?

      post :foo
      is('POST|post_foo').current_body?

      delete :foo
      is('DELETE|delete_foo').current_body?
    end

    Ensure 'verbified actions responds only to given request method' do
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

    Ensure 'only first matched verb used as request method' do
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
