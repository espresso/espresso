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
  end

  Spec.new RestApp do
    it "index should respond to any Request Method" do
      EspressoFrameworkConstants::HTTP__REQUEST_METHODS.each do |m|
        self.send m.to_s.downcase
        is_ok?
      end
    end

    testing 'defined actions responds only to given request method' do
      get :edit
      is_not_found?

      post :edit
      is_ok?

      get :create
      is_not_found?

      put :create
      is_ok?

      post :details
      is_not_found?

      head :details
      is_ok?

      head :edit
      is_not_found?
    end

    it 'uses only first verb as request method' do
      post :get_verb
      is(last_response).ok?

      get :verb
      is(last_response).not_found?
    end

  end
end