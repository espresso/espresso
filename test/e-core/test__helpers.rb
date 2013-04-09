module ECoreTest__Helpers
  module SomeHelper
    def foo
      'helper_method'
    end
  end

  class App < E
    include SomeHelper

    def index
      foo
    end
  end

  Spec.new App do
    get
    is('helper_method').ok_body?

    get :foo
    is(last_response).not_found?
  end

end
