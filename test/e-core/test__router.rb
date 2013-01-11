module ECoreTest__Router

  class App < E

    format '.html', '.xml'

    def index
      action
    end

    def exact arg
      arg
    end

    def post_exact arg
      arg
    end

    def one_or_two arg1, arg2 = nil
      [arg1, arg2]
    end

    def any *a
      a
    end

    def one_or_more arg1, *a
      [arg1, *a]
    end

    def rest_test action
      route action.to_sym
    end

  end

  Spec.new App do

    Testing 'with zero args' do
      It do
        r = get
        is('index').ok_body?

        r = post
        is('index').ok_body?

      end

      It 'returns 404 cause It does not accept any args' do
        r = get :a1
        is(last_response).not_found?

        r = get :a1, :a2
        is(last_response).not_found?
      end
    end

    Testing 'with one arg' do
      It do
        get :exact, :arg
        is('arg').ok_body?

        post :exact, :arg
        is('arg').ok_body?
      end

      It 'returns 404 cause called without args' do
        get :exact
        is(last_response).not_found?

        post :exact
        is(last_response).not_found?
      end

      It 'returns 404 cause redundant args provided' do
        post :exact, :arg, :redundant_arg
        is(last_response).not_found?
      end

      It 'returns 404 cause :head_exact action does not exists' do
        head :exact
        is(last_response).not_found?
      end
    end


    Testing 'with one or two args' do
      It do
        r = get :one_or_two, :a1
        is(['a1', nil].to_s).ok_body?

        r = get :one_or_two, :a1, :a2

        if E.is_ruby19?
          is(['a1', 'a2'].to_s).ok_body?
        else
          is(last_response).not_found?
          is('max params accepted: 1; params given: 2').current_body?
        end
      end

      It 'returns 404 cause no args provided' do
        r = get :one_or_two
        is(last_response).not_found?
      end

      It 'returns 404 cause redundant args provided' do
        r = get :one_or_two, 1, 2, 3, 4, 5, 6
        is(last_response).not_found?
      end

      It 'returns 404 cause :post_one_or_two action does not exists' do
        r = post :one_or_two
        is(last_response).not_found?
      end
    end

    Testing 'with one or more args' do
      It do
        r = get :one_or_more, :a1
        is(['a1'].to_s).ok_body?

        r = get :one_or_more, :a1, :a2, :a3, :etc
        if E.is_ruby19?
          is(['a1', 'a2', 'a3', 'etc'].to_s).ok_body?
        else
          #'return 404 cause trailing default params does not work on Appetite running on ruby1.8'
          is(last_response).not_found?
          is('max params accepted: 1; params given: 4').current_body?
        end
      end
    end

    Testing 'with any number of args' do
      r = get :any
      is([].to_s).ok_body?

      r = get :any, :number, :of, :args
      if E.is_ruby19?
        is(['number', 'of', 'args'].to_s).ok_body?
      else
        #'return 404 cause splat params does not work on Appetite running on ruby1.8' do
        is(last_response).not_found?
        is('max params accepted: 0; params given: 3').current_body?
      end
    end

    Ensure '`[]` and `route` works properly' do
      @map = {
        :index      => '',
        :exact      => '/exact',
        :post_exact => '/exact',
      }

      def check_route_functions(object, action, url)
        is?(object[action]) == url
        variations = [
            [[], url],
            [[:arg1],         url + '/arg1'],
            [[:arg1, :arg2],  url + '/arg1/arg2'],
            [[:arg1, {:var => 'val'}], url + '/arg1?var=val'],
            [[:arg1, {:var => 'val', :nil => nil}], url + '/arg1?var=val']
          ]
        variations.each do |args|
          is?(object.route(action, *args[0])) == args[1]
        end

        App.formats(action).each do |format|
          is?(object.route(action.to_s + format)) == (url + format)
          is?(object.route(action.to_s + '.blah')) == (map() + '/' + action.to_s + '.blah')
        end

        is?(object.route(:blah)) == (map() + '/blah')
      end

      Testing 'called at class level' do
        @map.each_pair do |action, url|
          url = map() + url
          check_route_functions(App, action, url)
        end
      end

      Testing 'when called at instance level' do
        ctrl = App.new(:index)
        @map.each_pair do |action, url|
          url = map() + url
          check_route_functions(ctrl, action, url)
        end
      end
    end

    Ensure 'route works correctly with deverbified actions' do
      get :rest_test, :post_exact
      is(App.base_url + '/exact').current_body?

      get :rest_test, :exact
      is(App.base_url + '/exact').current_body?
    end

  end
end
