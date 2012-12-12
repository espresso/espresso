module ECoreTest__Hooks

  class App < E

    before { @hooks ||= 0; @hooks += 1 }
    before { @hooks ||= 0; @hooks += 1 }
    after { response.body = [@hooks.to_s] }

    setup :index do
      before { @hooks ||= 0; @hooks += 1 }
      before { @hooks ||= 0; @hooks += 1 }
      after { response.body = [@hooks.to_s] }
    end

    setup :post_index do
      before { @hooks ||= 0; @hooks += 1 }
      before { @hooks ||= 0; @hooks += 1 }
      after { response.body = [@hooks.to_s] }
    end

    setup :get_params do
      after do
        body = action_params.is_a?(Hash) ? action_params[:id] : action_params[0]
        response.body = [body]
      end
    end

    setup :test_priority do
      before { (@priority_test ||= []) << :c }
      before(:priority => 100) { (@priority_test ||= []) << :a }
      before(:priority => 50) { (@priority_test ||= []) << :b }
      after(:priority => -100) { response.body = [@priority_test.inspect] }
    end

    format :json
    setup 'index.json' do
      before { @hooks ||= 0; @hooks += 1 }
    end

    def index
    end

    def post_index
    end

    def global
    end

    def wildcard_setup

    end

    def get_params id

    end

    def test_priority
    end

  end

  Spec.new App do

    Testing 'hook set for ALL actions' do
      get
      expect(last_response.body) == '4'

      post
      expect(last_response.body) == '4'
    end

    Testing 'hook set for SPECIFIC actions' do
      get :global
      expect(last_response.body) == '2'

      get :params, '100'
      expect(last_response.body) == '100'
    end

    Testing 'hook set for SPECIFIC actions on SPECIFIC format' do
      get
      is?(last_response.body) == '4'
      get 'index.json'
      is?(last_response.body) == '3'
    end

    Testing :priority do
      get :test_priority
      expect(last_response.body) == [:a, :b, :c].inspect
    end
  end
end
