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

    describe 'String name' do
      testing do
        app EApp.new(false).mount('ControllerNumberOne')
        get :one
        is_ok?
        get :two
        is_not_found?
      end

      it 'works with full qualified name' do
        app EApp.new(false).mount('ECoreTest__DiscoverControllers::ControllerNumberTwo')
        get :one
        is_not_found?
        get :two
        is_ok?
      end
    end

    describe 'Symbol name' do
      testing do
        app EApp.new(false).mount(:ControllerNumberTwo)
        get :one
        is_not_found?
        get :two
        is_ok?
      end
    end

    describe 'Regex name' do
      testing do
        app EApp.new(false).mount(/ControllerNumber/)
        get :one
        is_ok?
        get :two
        is_ok?
      end
    end

  end
end
