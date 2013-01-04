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
    it 'can access params by both string and symbol keys' do
      var, val = 'foo', 'bar'
      get :symbolized, var, false, var => val
      is_body? val

      var, val = 'foo', 'bar'
      get :symbolized, var, true, var => val
      is_body? val

      var, val = 'foo', 'bar'
      post :symbolized, var, false, var => val
      is_body? val

      var, val = 'foo', 'bar'
      post :symbolized, var, true, var => val
      is_body? val
    end

    if RUBY_VERSION.to_f > 1.8
      describe 'splat params' do

        it 'works with zero and more' do
          get :splat_params_0
          is_ok_body? '{:args=>[]}'

          get :splat_params_0, 1, 2, 3
          is_ok_body? '{:args=>["1", "2", "3"]}'
        end

        it 'works with one and more' do

          get :splat_params_1
          is_not_found?
          is_body? %r{min params accepted\: 1}

          get :splat_params_1, 1
          is_ok_body? '{:a1=>"1", :args=>[]}'

          get :splat_params_1, 1, 2, 3
          is_ok_body? '{:a1=>"1", :args=>["2", "3"]}'
        end

      end
    end

    describe 'nested params' do
      specify do
        params = {"user"=>{"username"=>"user", "password"=>"pass"}}

        # using regex cause ruby1.8 sometimes reverses the order
        regex  = Regexp.union(/"user"=>/, /"username"=>"user"/, /"password"=>"pass"/)

        get :nested, params
        is_body? regex

        post :nested, params
        is_body? regex
      end
    end
  end

  Spec.new ActionParams do
    if RUBY_VERSION.to_f > 1.8
      it  do
        a1, a2 = rand.to_s, rand.to_s
        get a1, a2
        is_body? ({:a1 => a1, :a2 => a2}).inspect
        get a1
        is_body? ({:a1 => a1, :a2 => nil}).inspect
      end
    else
      it 'returns 404 cause trailing default params does not work on Appetite running on ruby1.8' do
        a1, a2 = rand.to_s, rand.to_s
        get a1, a2
        is_not_found?
        is_body? 'max params accepted: 1; params given: 2'
      end
      it "works with one default param" do
        a1 = rand.to_s
        get a1
        is_body? [a1].inspect
      end
    end
  end
end
