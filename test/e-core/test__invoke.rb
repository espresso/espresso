module ECoreTest__Pass

  module Cms
    class Page < E
      map '/'

      def index key, val
        pass :destination, key, val
        puts 'this should not be happen'
        raise :something
      end

      def post_index key, val
        pass :post_destination, key, val
      end
      
      def put_index
        pass :post_destination, 1, 2
      end

      def not_found_test
        pass :blah
      end

      def custom_query_string key, val
        pass :destination, key, val, key => val
      end

      def destination key, val
        [[key, val], params].inspect
      end

      def post_destination key, val
        [[key, val], params].inspect
      end

      def inner_app action, key, val
        pass InnerApp, action.to_sym, key, val
      end

      def get_invoke action, key, val
        s,h,b = invoke(InnerApp, action.to_sym, key, val)
        [s, b.first].join('/')
      end

      def get_fetch action, key, val
        fetch(:destination, key, val)
      end
      def get_fetch_inner action, key, val
        fetch(InnerApp, action.to_sym, key, val)
      end

      def get_xhr_pass action
        xhr_pass action
      end

      def get_xhr_pass_via_post action
        xhr_pass_via_post action
      end

      def get_xhr_fetch action
        xhr_fetch action
      end

      def get_xhr_fetch_via_post action
        xhr_fetch_via_post action
      end

      def xhr_destination
        rq.xhr?.inspect
      end

      def post_xhr_post_destination
        [rq.xhr?, rq.post?].inspect
      end
    end

    class InnerApp < E
      map '/'

      def catcher key, val
        [[key, val].join('='), params.to_a.map {|e| e.join('=')}].join('/')
      end
    end
  end

  Spec.new self do
    app Cms.mount

    ARGS   = ["k", "v"]
    PARAMS = {"var" => "val"}

    def args
      ARGS.join('/')
    end
    def params
      PARAMS.dup
    end

    Testing :get_pass do
      get args, params
      refute(last_response.body) =~ /index/
      is([ARGS, PARAMS].inspect).current_body?
    end

    Testing :post_pass do
      post args, params
      is([ARGS, PARAMS].inspect).current_body?
    end

    Should 'return 501 cause :put_destination missing' do
      put
      is(last_response).not_implemented?
    end

    Should 'return 404' do
      get :not_found_test
      is(last_response).not_found?
    end

    Testing :custom_query_string do
      get :custom_query_string, args, params
      is([ARGS, {ARGS.first => ARGS.last}].inspect).current_body?
    end

    Testing :inner_app do
      get :inner_app, :catcher, args, params
      is("k=v/var=val").current_body?
    end

    Ensure 'invoke does not pass data' do
      get :invoke, :catcher, args, params
      is("200/k=v/").current_body?
    end

    Testing :fetch do
      Ensure 'fetch does not pass data' do
        get :fetch, :catcher, args, params
        is([ARGS, {}].inspect).current_body?
      end
      Should 'work well with inner controllers' do
        get :fetch_inner, :catcher, args, params
        is("k=v/").current_body?
      end
    end

    Should 'pass via XHR' do
      get :xhr_pass, :xhr_destination
      is('true').current_body?
    end

    Should 'pass via XHR using POST' do
      get :xhr_pass_via_post, :xhr_post_destination
      is('[true, true]').current_body?
    end

    Should 'fetch via XHR' do
      get :xhr_fetch, :xhr_destination
      is('true').current_body?
    end

    Should 'fetch via XHR using POST' do
      get :xhr_fetch_via_post, :xhr_post_destination
      is('[true, true]').current_body?
    end

  end
end
