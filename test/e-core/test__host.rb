module ECoreTest__Host

  class App < E
    map host: 'http://foo.bar'
  end

  Spec.new App do
    get
    is(last_response).not_found?

    header['HTTP_HOST'] = 'foo.bar'
    get
    is(last_response).ok?

    header['HTTP_HOST'] = 'bar.foo'
    get
    is(last_response).not_found?
  end

  module Slice
    class App < E
    end
  end

  Spec.new Slice do
    app E.new {
      mount Slice, '/', hosts: ['foo.com', 'foo.net']
    }
    map Slice::App.base_url

    get
    is(last_response).not_found?

    header['HTTP_HOST'] = 'foo.com'
    get
    is(last_response).ok?
    
    header['HTTP_HOST'] = 'foo.net'
    get
    is(last_response).ok?
  end

  class App2 < E
    map host: 'dothub.com'
  end

  Spec.new self do
    app E.new {
      map host: 'some.thing.com'
      mount App2
    }
    map App2.base_url

    get
    is(last_response).not_found?

    header['HTTP_HOST'] = 'some.thing.com'
    get
    is(last_response).ok?

    header['HTTP_HOST'] = 'dothub.com'
    get
    is(last_response).ok?
  end
end
