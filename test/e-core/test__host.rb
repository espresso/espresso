module ECoreTest__Host

  class App < E
    map host: 'foo.bar'
  end

  Spec.new App do
    Should 'listen on default host' do
      get
      is(last_response).ok?
    end

    Should 'listen on specified hosts' do
      header['HTTP_HOST'] = 'foo.bar'
      get
      is(last_response).ok?
    end

    Should 'reject foreign hosts' do
      header['HTTP_HOST'] = 'evil.tld'
      get
      is(last_response).not_found?
    end
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

    Should 'listen on default host' do
      get
      is(last_response).ok?
    end

    Should 'listen on specified hosts' do
      header['HTTP_HOST'] = 'foo.com'
      get
      is(last_response).ok?
      
      header['HTTP_HOST'] = 'foo.net'
      get
      is(last_response).ok?
    end

    Should 'reject foreign hosts' do
      header['HTTP_HOST'] = 'evil.tld'
      get
      is(last_response).not_found?
    end
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

    Should 'listen on default host' do
      get
      is(last_response).ok?
    end

    Should 'listen on specified hosts' do
      header['HTTP_HOST'] = 'some.thing.com'
      get
      is(last_response).ok?

      header['HTTP_HOST'] = 'dothub.com'
      get
      is(last_response).ok?
    end

    Should 'reject foreign hosts' do
      header['HTTP_HOST'] = 'evil.tld'
      get
      is(last_response).not_found?
    end
  end
end
