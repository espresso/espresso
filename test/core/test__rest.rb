module ECoreTest__REST

  class App < E

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
  end

  Spec.new App do

    def ok? response
      check(response.status) == 200
    end

    def not_found? response
      check(response.status) == 404
    end

    Testing "index, it should respond to any Request Method" do
      EspressoFrameworkConstants::HTTP__REQUEST_METHODS.each do |m|
        self.send m.to_s.downcase
        is(last_response).ok?
      end
    end

    Ensure 'defined actions responds only to given request method' do

      get :edit
      is(last_response).not_found?

      post :edit
      is(last_response).ok?

      get :create
      is(last_response).not_found?

      put :create
      is(last_response).ok?

      post :details
      is(last_response).not_found?

      head :details
      is(last_response).ok?

      head :edit
      is(last_response).not_found?
    end

    Ensure 'it uses only first verb as request method' do
      post :get_verb
      is(last_response).ok?

      get :verb
      is(last_response).not_found?
    end

  end

end
