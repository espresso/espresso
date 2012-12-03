module ECoreTest__Canonical

  class App < E
    map '/', '/cms', '/pages'

    def index
     rq.path
    end

    def post_eatme
      rq.path
    end

  end

  module Hlp
    def ok? response
      check(response.status) == AppetiteConstants::STATUS__OK
    end
  end

  Spec.new self do

    include Hlp
    app(App.mount '/', '/a')

    Testing :base_url do
      get :index
      is(last_response).ok?
      is?(last_response.body) == '/index'

      get
      is(last_response).ok?
      is?(last_response.body) == '/'

      post :eatme
      is(last_response).ok?
      is?(last_response.body) == '/eatme'
    end

    Testing :controller_canonicals do
      get :cms, :index
      is(last_response).ok?
      is?(last_response.body) == '/cms/index'

      get :cms
      is(last_response).ok?
      is?(last_response.body) == '/cms'

      post :cms, :eatme
      is(last_response).ok?
      is?(last_response.body) == '/cms/eatme'

      get :pages, :index
      is(last_response).ok?
      is?(last_response.body) == '/pages/index'

      get :pages
      is(last_response).ok?
      is?(last_response.body) == '/pages'

      post :pages, :eatme
      is(last_response).ok?
      is?(last_response.body) == '/pages/eatme'
    end
  end

  Spec.new self do

    include Hlp
    app(App.mount '/', '/a')

    Testing :app_canonicals do

      get :a
      is(last_response).ok?
      is?(last_response.body) == '/a'

      get :a, :cms, :index
      is(last_response).ok?
      is?(last_response.body) == '/a/cms/index'

      get :a, :cms
      is(last_response).ok?
      is?(last_response.body) == '/a/cms'

      post :a, :cms, :eatme
      is(last_response).ok?
      is?(last_response.body) == '/a/cms/eatme'

      get :a, :pages, :index
      is(last_response).ok?
      is?(last_response.body) == '/a/pages/index'

      get :a, :pages
      is(last_response).ok?
      is?(last_response.body) == '/a/pages'

      post :a, :pages, :eatme
      is(last_response).ok?
      is?(last_response.body) == '/a/pages/eatme'
    end

  end
end
