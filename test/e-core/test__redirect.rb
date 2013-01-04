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

  Spec.new Cms::Pages do
    def vars_redirected?(val)
      is?(VARS['redirected']) == val
    end

    testing :redirect do
      VARS['redirected'] = (rand = rand())
      get :test_redirect
      is_redirect?
      is_location? Cms::Pages.route(:index, :var => :val)
      vars_redirected? rand
    end

    testing :permanent_redirect do
      VARS['redirected'] = (rand = rand())
      get :test_permanent_redirect
      is_redirect? 301
      vars_redirected? rand
    end

    testing :delayed_redirect do
      VARS['redirected'] = (rand = rand())
      get :test_delayed_redirect
      is_redirect?
      vars_redirected? :test_delayed_redirect
    end

    testing :reload do
      get :test_reload, :reload => '1'
      is_redirect?
      follow_redirect!
      is_ok_body? 'reloaded'
    end

    testing :inner_app do
      get :inner_app
      is_redirect?
      is_location? Cms::News.route(:index, :var => :val)
    end

    testing :redirect_outer do
      target = 'http://google.com'
      get :redirect_outer, :target => target
      is_redirect?
      is_location? target
    end

  end
end
