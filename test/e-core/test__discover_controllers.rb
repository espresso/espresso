module ECoreTest__DiscoverControllers

  class ControllerNumberOne < E
    map '/'

    def one

    end
  end
  class ControllerNumberTwo < E
    map '/'

    def two

    end
  end

  Spec.new self do

    Testing 'String name' do
      app EApp.new(false).mount('ControllerNumberOne')
      get :one
      expect(last_response.status) == 200
      get :two
      expect(last_response.status) == 404

      Should 'also work with full qualified name' do
        app EApp.new(false).mount('ECoreTest__DiscoverControllers::ControllerNumberTwo')
        get :one
        expect(last_response.status) == 404
        get :two
        expect(last_response.status) == 200
      end
    end

    Testing 'Symbol name' do
      app EApp.new(false).mount(:ControllerNumberTwo)
      get :one
      expect(last_response.status) == 404
      get :two
      expect(last_response.status) == 200
    end

    Testing 'Regex name' do
      app EApp.new(false).mount(/ControllerNumber/)
      get :one
      expect(last_response.status) == 200
      get :two
      expect(last_response.status) == 200
    end

  end
end
