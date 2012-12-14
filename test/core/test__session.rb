module ECoreTest__Session

  class App < E

    before { session['needed here to load session'] }

    def set var, val
      session[var] = val
    end

    def get var
      session[var] || 'notSet'
    end

    def keys
      session.keys.inspect
    end

    def values
      session.values.inspect
    end

    def flash_set var, val
      flash[var] = val
    end

    def flash_get var
      flash[var] || 'notSet'
    end

    def delete var
      session.delete[var]
    end
  end

  Spec.new App do
    app EApp.new { session :memory }.mount(App)
    map App.base_url

    var, val = 2.times.map { rand.to_s }
    get :set, var, val

    5.times do
      r = get :get, var
      expect(r.body) =~ /#{val}/
    end

    Testing 'keys/values' do
      get :keys
      expect(last_response.body) == [var].inspect

      get :values
      expect(last_response.body) == [val].inspect
    end

    Testing :flash do
      var, val = rand.to_s, rand.to_s
      get :flash_set, var, val

      r = get :flash_get, var
      expect(r.body) =~ /#{val}/

      r = get :flash_get, var
      expect(r.body) =~ /notSet/
    end

  end

end
