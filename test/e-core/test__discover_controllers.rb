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

    Describe 'String name' do
      Testing do
        app EApp.new(false).mount('ControllerNumberOne')
        get :one
        is(last_response).ok?
        get :two
        is(last_response).not_found?
      end

      It 'works with full qualified name' do
        app EApp.new(false).mount('ECoreTest__DiscoverControllers::ControllerNumberTwo')
        get :one
        is(last_response).not_found?
        get :two
        is(last_response).ok?
      end
    end

    Describe 'Symbol name' do
      Testing do
        app EApp.new(false).mount(:ControllerNumberTwo)
        get :one
        is(last_response).not_found?
        get :two
        is(last_response).ok?
      end
    end

    Describe 'Regex name' do
      Testing do
        app EApp.new(false).mount(/ControllerNumber/)
        get :one
        is(last_response).ok?
        get :two
        is(last_response).ok?
      end
    end

  end
end
