module ECoreTest__Params

  class App < E

    def symbolized var, symbolize
    end
    def post_symbolized var, symbolize
    end
    after /symbolized/ do
      var, symbolize = action_params__array[0..1]
      response.body  = [params[symbolize == 'true' ? var.to_sym : var]]
    end

    def splat_params_0 *args
      action_params.inspect
    end

    def splat_params_1 a1, *args
      action_params.inspect
    end

    def get_nested
      params.inspect
    end

    def post_nested
      params.inspect
    end
  end

  Spec.new App do
    It 'can access params by both string and symbol keys' do
      var, val = 'foo', 'bar'
      get :symbolized, var, false, var => val
      is(val).current_body?

      var, val = 'foo', 'bar'
      get :symbolized, var, true, var => val
      is(val).current_body?

      var, val = 'foo', 'bar'
      post :symbolized, var, false, var => val
      is(val).current_body?

      var, val = 'foo', 'bar'
      post :symbolized, var, true, var => val
      is(val).current_body?
    end

    Describe 'splat params' do

      It 'works with zero and more' do
        get :splat_params_0
        is('{:args=>[]}').ok_body?

        get :splat_params_0, 1, 2, 3
        is('{:args=>["1", "2", "3"]}').ok_body?
      end

      It 'works with one and more' do
        get :splat_params_1
        is(last_response).not_found?
        does(%r{min params accepted\: 1}).match_body?

        get :splat_params_1, 1
        is('{:a1=>"1", :args=>[]}').ok_body?

        get :splat_params_1, 1, 2, 3
        is('{:a1=>"1", :args=>["2", "3"]}').ok_body?
      end
    end

    Testing 'nested params' do
      params = {"user"=>{"username"=>"user", "password"=>"pass"}}

      regex  = Regexp.union(/"user"=>/, /"username"=>"user"/, /"password"=>"pass"/)

      get :nested, params
      does(regex).match_body?

      post :nested, params
      does(regex).match_body?
    end
  end

  class ActionParams < E
    def one a1
      action_params.inspect
    end

    def two a1, a2 = nil
      action_params.inspect
    end
  end
  Spec.new ActionParams do
    
    Should 'return a Hash' do
      a1, a2 = rand.to_s, rand.to_s

      get :one, a1
      is({:a1 => a1}.inspect).current_body?

      get :two, a1, a2
      is({:a1 => a1, :a2 => a2}.inspect).current_body?

      get :two, a1
      is({:a1 => a1, :a2 => nil}.inspect).current_body?
    end
  end
end
