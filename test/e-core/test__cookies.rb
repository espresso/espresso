module ECoreTest__Cookies

  class App < E

    def set var, val
      cookies[var] = {:value => val, :path => '/'}
    end

    def get var
      cookies[var]
    end

    def keys
      cookies.keys.inspect
    end

    def values
      cookies.values.inspect
    end

  end

  Spec.new App do

    Testing 'set/get' do
      var, val = 2.times.map { rand.to_s }
      get :set, var, val
      r = get :get, var
      expect(r.body) =~ /#{val}/

      Testing 'keys/values' do
        get :keys
        expect(last_response.body) == [var].inspect

        get :values
        expect(last_response.body) == [val].inspect
      end
    end

  end

end
