module ECoreTest__Pass

  module Cms
    class Page < E
      map '/'

      def index key, val
        pass :destination, key, val
        puts 'this should not be happen'
        exit 1
      end

      def post_index key, val
        pass :post_destination, key, val
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
        invoke(InnerApp, action.to_sym, key, val).inspect
      end

      def get_fetch action, key, val
        fetch(InnerApp, action.to_sym, key, val).inspect
      end
    end

    class InnerApp < E
      map '/'

      def catcher key, val
        [[key, val], params].inspect
      end
    end
  end

  Spec.new self do
    app Cms.mount

    ARGS = ["k", "v"].freeze
    PARAMS = {"var" => "val"}.freeze

    Test :get_pass do
      body = get(ARGS.join('/'), PARAMS.dup).body
      refute(body) =~ /index/
      expect(body) == [ARGS, PARAMS].inspect
    end

    Test :post_pass do
      body = post(ARGS.join('/'), PARAMS.dup).body
      is(body) == [ARGS, PARAMS].inspect
    end

    Test :custom_query_string do
      body = get(:custom_query_string, ARGS.join('/'), PARAMS.dup).body
      expect(body) == [ARGS, {ARGS.first => ARGS.last}].inspect
    end

    Test :inner_app do
      body = get(:inner_app, :catcher, ARGS.join('/'), PARAMS.dup).body
      is(body) == [ARGS, PARAMS].inspect
    end

    Test :invoke do
      r = get :invoke, :catcher, ARGS.join('/'), PARAMS.dup
      check(r.body) =~ /\A\[200/
      check(r.body) =~ /"Content\-Type"=>"text\/html"/
      check(r.body) =~ /#{Regexp.escape '[\"k\", \"v\"]'}/
      check(r.body) =~ /#{Regexp.escape '{\"var\"=>\"val\"}'}/
    end

    Test :fetch do
      r = get :fetch, :catcher, ARGS.join('/'), PARAMS.dup
      check(r.body) =~ /#{Regexp.escape '[\"k\", \"v\"]'}/
      check(r.body) =~ /#{Regexp.escape '{\"var\"=>\"val\"}'}/
    end

  end
end
