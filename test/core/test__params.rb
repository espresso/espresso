module ECoreTest__Params

  class App < E

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

  Spec.new App do

    Should 'be able to access params by both string and symbol keys' do
      var, val = 'foo', 'bar'
      get :symbolized, var, false, var => val
      expect( last_response.body ) == val

      var, val = 'foo', 'bar'
      get :symbolized, var, true, var => val
      expect( last_response.body ) == val

      var, val = 'foo', 'bar'
      post :symbolized, var, false, var => val
      expect( last_response.body ) == val

      var, val = 'foo', 'bar'
      post :symbolized, var, true, var => val
      expect( last_response.body ) == val
    end

    if RUBY_VERSION.to_f > 1.8
      Testing 'splat params' do

        Ensure 'it works with zero and more' do
          get :splat_params_0
          expect(last_response.status) == 200
          expect(last_response.body)   == '{:args=>[]}'

          get :splat_params_0, 1, 2, 3
          expect(last_response.status) == 200
          expect(last_response.body)   == '{:args=>["1", "2", "3"]}'
        end

        Ensure 'it works with one and more' do
          
          get :splat_params_1
          expect(last_response.status) == 404
          does(last_response.body).include?('min params accepted: 1')

          get :splat_params_1, 1
          expect(last_response.status) == 200
          expect(last_response.body)   == '{:a1=>"1", :args=>[]}'

          get :splat_params_1, 1, 2, 3
          expect(last_response.status) == 200
          expect(last_response.body)   == '{:a1=>"1", :args=>["2", "3"]}'
        end

      end
    end

    Testing 'nested params' do
      params = {"user"=>{"username"=>"user", "password"=>"pass"}}

      # using regex cause ruby1.8 sometimes reverses the order
      regex  = Regexp.union(/"user"=>/, /"username"=>"user"/, /"password"=>"pass"/)

      get :nested, params
      does(last_response.body) =~ regex
      
      post :nested, params
      does(last_response.body) =~ regex
    end

  end

  Spec.new ActionParams do
    a1, a2 = rand.to_s, rand.to_s
    r1 = get a1, a2
    r2 = get a1

    if RUBY_VERSION.to_f > 1.8
      expect(r1.body) == {:a1 => a1, :a2 => a2}.inspect
      expect(r2.body) == {:a1 => a1, :a2 => nil}.inspect
    else
      Should 'return 404 cause trailing default params does not work on E running on ruby1.8' do
        is?(r1.status) == 404
        expect(r1.body) == 'max params accepted: 1; params given: 2'
      end
      expect(r2.body) == [a1].inspect
    end
  end
end
