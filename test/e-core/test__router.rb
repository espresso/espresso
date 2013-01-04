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

  end

  Spec.new App do

    describe 'zero args' do
      it do
        r = get
        is_ok_body? 'index'

        r = post
        is_ok_body? 'index'

      end

      it 'returns 404 cause it does not accept any args' do
        r = get :a1
        is_not_found?

        r = get :a1, :a2
        is_not_found?
      end
    end

    describe 'one arg' do
      it do
        get :exact, :arg
        is_ok_body? 'arg'

        post :exact, :arg
        is_ok_body? 'arg'
      end

      it 'returns 404 cause called without args' do
        get :exact
        is_not_found?

        post :exact
        is_not_found?
      end

      it 'return 404 cause redundant args provided' do
        post :exact, :arg, :redundant_arg
        is_not_found?
      end

      it 'return 404 cause :head_exact action does not exists' do
        head :exact
        is_not_found?
      end
    end


    describe 'one or two args' do
      it do
        r = get :one_or_two, :a1
        is_ok_body? ['a1', nil].to_s

        r = get :one_or_two, :a1, :a2

        if E.is_ruby19?
          is_ok_body? ['a1', 'a2'].to_s
        else
          is_not_found?
          is_body? 'max params accepted: 1; params given: 2'
        end
      end

      it 'return 404 cause no args provided' do
        r = get :one_or_two
        is_not_found?
      end

      it 'return 404 cause redundant args provided' do
        r = get :one_or_two, 1, 2, 3, 4, 5, 6
        is_not_found?
      end

      it 'return 404 cause :post_one_or_two action does not exists' do
        r = post :one_or_two
        is_not_found?
      end
    end

    describe 'one or more' do
      it do
        r = get :one_or_more, :a1
        is_ok_body? ['a1'].to_s

        r = get :one_or_more, :a1, :a2, :a3, :etc
        if E.is_ruby19?
          is_ok_body? ['a1', 'a2', 'a3', 'etc'].to_s
        else
          #'return 404 cause trailing default params does not work on Appetite running on ruby1.8'
          is_not_found? 404
          is_body? 'max params accepted: 1; params given: 4'
        end
      end
    end

  describe 'any number of args' do
      it do
        r = get :any
        is_ok_body? [].to_s

        r = get :any, :number, :of, :args
        if E.is_ruby19?
          is_ok_body? ['number', 'of', 'args'].to_s
        else
          #'return 404 cause splat params does not work on Appetite running on ruby1.8' do
          is_not_found?
          is_body? 'max params accepted: 0; params given: 3'
        end
      end
    end




    describe '`[]` and `route` works properly' do
      @map = {
          :index      => '/index',
          :exact      => '/exact',
          :post_exact => '/exact',
        }

      def check_route_functions(object, action, url)
        is?(object[action]) == url
        variations = [
            [[], url],
            [[:arg1],         url + '/arg1'],
            [[:arg1, :arg2],  url + '/arg1/arg2'],
            [[:arg1, :var => 'val'], url + '/arg1?var=val'],
            [[:arg1, :var => 'val', :nil => nil], url + '/arg1?var=val']
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

      it 'called at class level' do
        @map.each_pair do |action, url|
          url = map() + url
          check_route_functions(App, action, url)
        end
      end

      it 'when called at instance level' do
        ctrl = App.new
        @map.each_pair do |action, url|
          url = map() + url
          check_route_functions(ctrl, action, url)
        end
      end
    end
  end
end