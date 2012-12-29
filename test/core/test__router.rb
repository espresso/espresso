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

    Testing 'zero args' do
      r = get
      is?(r.status) == 200
      is?(r.body) == 'index'

      r = post
      is?(r.status) == 200
      is?(r.body) == 'index'

      Should 'return 404 cause it does not accept any args' do
        r = get :a1
        is?(r.status) == 404

        r = get :a1, :a2
        is?(r.status) == 404
      end

    end

    Testing 'one arg' do
      r = get :exact, :arg
      is?(r.status) == 200
      is?(r.body) == 'arg'

      r = post :exact, :arg
      is?(r.status) == 200
      is?(r.body) == 'arg'

      Should 'return 404 cause called without args' do
        r = get :exact
        is?(r.status) == 404

        r = post :exact
        is?(r.status) == 404
      end

      Should 'return 404 cause redundant args provided' do
        r = post :exact, :arg, :redundant_arg
        is?(r.status) == 404
      end

      Should 'return 404 cause :head_exact action does not exists' do
        r = head :exact
        expect(r.status) == 404
      end
    end

    Testing 'one or two args' do
      r = get :one_or_two, :a1
      is?(r.status) == 200
      is?(r.body) == ['a1', nil].to_s

      r = get :one_or_two, :a1, :a2
      if RUBY_VERSION.to_f > 1.8
        is?(r.status) == 200
        is?(r.body) == ['a1', 'a2'].to_s
      else
        is?(r.status) == 404
        is?(r.body) == 'max params accepted: 1; params given: 2'
      end

      Should 'return 404 cause no args provided' do
        r = get :one_or_two
        expect(r.status) == 404
      end

      Should 'return 404 cause redundant args provided' do
        r = get :one_or_two, 1, 2, 3, 4, 5, 6
        expect(r.status) == 404
      end

      Should 'return 404 cause :post_one_or_two action does not exists' do
        r = post :one_or_two
        expect(r.status) == 404
      end
    end

    Testing 'one or more' do
      r = get :one_or_more, :a1
      is?(r.status) == 200
      is?(r.body) == ['a1'].to_s

      r = get :one_or_more, :a1, :a2, :a3, :etc
      if RUBY_VERSION.to_f > 1.8
        is?(r.status) == 200
        is?(r.body) == ['a1', 'a2', 'a3', 'etc'].to_s
      else
        Should 'return 404 cause trailing default params does not work on E running on ruby1.8' do
          is?(r.status) == 404
          is?(r.body) == 'max params accepted: 1; params given: 4'
        end
      end
    end

    Testing 'any number of args' do
      r = get :any
      is?(r.status) == 200
      is?(r.body) == [].to_s

      r = get :any, :number, :of, :args
      if RUBY_VERSION.to_f > 1.8
        is?(r.status) == 200
        is?(r.body) == ['number', 'of', 'args'].to_s
      else
        Should 'return 404 cause splat params does not work on E running on ruby1.8' do
          is?(r.status) == 404
          is?(r.body) == 'max params accepted: 0; params given: 3'
        end
      end

    end

    Ensure '`[]` and `route` works properly' do
      map = {
          :index => '/index',
          :exact => '/exact',
          :post_exact => '/exact',
      }

      When 'called at class level' do
        map.each_pair do |action, url|
          url = map() + url
          expect(App[action]) == url

          expect(App.route action) == url
          expect(App.route action, :arg1) == url + '/arg1'
          expect(App.route action, :arg1, :arg2) == url + '/arg1/arg2'
          expect(App.route action, :arg1, :var => 'val') == url + '/arg1?var=val'
          expect(App.route action, :arg1, :var => 'val', :nil => nil) == url + '/arg1?var=val'

          App.formats(action).each do |format|
            expect(App.route action.to_s + format) == url + format
            is(App.route action.to_s + '.blah') == map() + '/' + action.to_s + '.blah'
          end

        end

        is(App.route :blah) == map() + '/blah'

      end

      And 'when called at instance level' do
        ctrl = App.allocate

        map.each_pair do |action, url|
          url = map() + url
          expect(ctrl[action]) == url
          expect(ctrl.route action) == url
          expect(ctrl.route action, :nil => nil) == url

          App.formats(action).each do |format|
            expect(ctrl.route(action.to_s + format)) == url + format
            is(ctrl.route(action.to_s + '.blah')) == map() + '/' + action.to_s + '.blah'
          end
        end

        is(ctrl.route :blah) == map() + '/blah'

      end
    end

  end
end
