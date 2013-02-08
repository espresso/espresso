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
      does(/#{val}/).match_body?

      Testing 'keys/values' do
        get :keys
        is([var].inspect).current_body?

        get :values
        is([val].inspect).current_body?
      end
    end
  end
end
