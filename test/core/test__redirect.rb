module ECoreTest__Redirect

  VARS = {}

  module Cms

    class Pages < E
      map '/'

      def index
        "index"
      end

      def test_redirect
        redirect :index, :var => :val
        # code here never executed
        VARS['redirected'] = true
      end

      def test_permanent_redirect
        permanent_redirect :index
        # code here never executed
        VARS['redirected'] = true
      end

      def test_delayed_redirect
        delayed_redirect :index
        # this should be executed on delayed redirect
        VARS['redirected'] = __method__
      end

      def test_reload
        params['reload'].to_i > 0 && reload(:reload => '0')
        'reloaded'
      end

      def inner_app
        redirect News, :index, :var => :val
      end

      def redirect_outer
        redirect params['target']
      end

    end

    class News < E
      map '/'

      def index

      end
    end
    News.mount
  end

  Spec.new self do
    app Cms::Pages.mount
    map Cms::Pages.base_url

    def redirected? response, status = 302
      check(response.status) == status
    end

    Test :redirect do

      VARS['redirected'] = (rand = rand())
      get :test_redirect
      was(last_response).redirected?
      is?(last_response.headers['Location']) == Cms::Pages.route(:index, :var => :val)
      is?(VARS['redirected']) == rand
    end

    Test :permanent_redirect do

      VARS['redirected'] = (rand = rand())
      get :test_permanent_redirect
      was(last_response).redirected? 301
      is?(VARS['redirected']) == rand
    end

    Test :delayed_redirect do

      VARS['redirected'] = (rand = rand())
      get :test_delayed_redirect
      was(last_response).redirected?
      is?(VARS['redirected']) == :test_delayed_redirect
    end

    Test :reload do
      get :test_reload, :reload => '1'
      was(last_response).redirected?
      follow_redirect!
      is?(last_response.status) == 200
      is?(last_response.body) == 'reloaded'
    end

    Test :inner_app do
      get :inner_app
      was(last_response).redirected?
      is?(last_response.headers['Location']) == Cms::News.route(:index, :var => :val)
    end

    Test :redirect_outer do
      target = 'http://google.com'
      get :redirect_outer, :target => target
      was(last_response).redirected?
      is?(last_response.headers['Location']) == target
    end

  end
end
