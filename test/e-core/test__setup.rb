module ECoreTest__Setup
  class App < E
    format '.xml', '.json'
    disable_format_for :baz, /bla/

    cache_control :public

    setup do
    end

    setup :foo do
    end

    setup /oo/ do
    end

    setup :foo, :bar do
    end

    setup :bar, /f/ do
    end

    on '.xml' do
    end

    on '.json' do
    end

    before :foo, 'bar.json' do
    end

    before /bl/ do
    end

    after /la/ do
    end

    after :black do
    end

    after do
      response.body = [[setups(:a), setups(:z)].map {|e| e.size}.join('/')]
    end

    def foo
    end

    def bar
    end

    def baz
    end

    def blah
    end

    def black
    end
  end

  Spec.new App do

    Testing :matchers do
      get :foo
      expect(last_response.body) == '7/1'

      get 'foo.xml'
      expect(last_response.body) == '8/1'

      get 'foo.json'
      expect(last_response.body) == '8/1'

      get :bar
      expect(last_response.body) == '4/1'

      get 'bar.xml'
      expect(last_response.body) == '5/1'

      get 'bar.json'
      expect(last_response.body) == '6/1'

      get :blah
      expect(last_response.body) == '3/2'

      get :black
      expect(last_response.body) == '3/3'
    end

    Ensure 'format disabled' do
      Testing 'exact matcher' do
        get :blah
        expect(last_response.status) == 200

        get 'blah.xml'
        expect(last_response.status) == 404

        get 'blah.json'
        expect(last_response.status) == 404
      end
      
      Testing 'regex matcher' do
        get :black
        expect(last_response.status) == 200

        get 'black.xml'
        expect(last_response.status) == 404

        get 'black.json'
        expect(last_response.status) == 404
      end
    end

  end
end
