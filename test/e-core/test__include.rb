module ECoreTest__Include
  
  module SharedActions

    def foo
      'foo_from_module'
    end

    def bar baz
      'bar_from_module+' + baz
    end
  end

  class App < E
    include SharedActions
  end

  class Override < E
    include SharedActions

    def bar baz
      'bar_from_class+' + baz
    end
  end

  Spec.new App do
    get :foo
    is(last_response).ok?
    is('foo_from_module').current_body?

    get :bar, :blah
    is(last_response).ok?
    is('bar_from_module+blah').current_body?
  end

  Spec.new Override do
    get :foo
    is(last_response).ok?
    is('foo_from_module').current_body?

    get :bar, :blah
    is(last_response).ok?
    is('bar_from_class+blah').current_body?
  end

end
