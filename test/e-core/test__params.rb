module ECoreTest__Params

  class ParamsApp < E

    def symbolized var, symbolize
      params[symbolize == 'true' ? var.to_sym : var]
    end

    if RUBY_VERSION.to_f > 1.8
      def splat_params_0 *args
        action_params.inspect
      end

      def splat_params_1 a1, *args
        action_params.inspect
      end
    end

    def get_nested
      params.inspect
    end

    def post_nested
      params.inspect
    end

  end

  class ActionParams < E

    def index a1, a2 = nil
      action_params.inspect
    end
  end

  Spec.new ParamsApp do
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

    if RUBY_VERSION.to_f > 1.8
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
    end

    Describe 'nested params' do
      params = {"user"=>{"username"=>"user", "password"=>"pass"}}

      # using regex cause ruby1.8 sometimes reverses the order
      regex  = Regexp.union(/"user"=>/, /"username"=>"user"/, /"password"=>"pass"/)

      get :nested, params
      does(regex).match_body?

      post :nested, params
      does(regex).match_body?
    
    end
  end

  Spec.new ActionParams do
    if RUBY_VERSION.to_f > 1.8
      It  do
        a1, a2 = rand.to_s, rand.to_s
        get a1, a2
        is({:a1 => a1, :a2 => a2}.inspect).current_body?
        get a1
        is({:a1 => a1, :a2 => nil}.inspect).current_body?
      end
    else
      It 'returns 404 cause trailing default params does not work on Appetite running on ruby1.8' do
        a1, a2 = rand.to_s, rand.to_s
        get a1, a2
        is(last_response).not_found?
        is('max params accepted: 1; params given: 2').current_body?
      end
      It "works with one default param" do
        a1 = rand.to_s
        get a1
        is([a1].inspect).current_body?
      end
    end
  end
end
