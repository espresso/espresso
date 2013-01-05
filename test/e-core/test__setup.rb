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
      # FIXME: this is a fragile test...
      variations = {
        :foo       => '7/1',
        'foo.xml'  => '8/1',
        'foo.json' => '8/1',
        'bar'      => '4/1',
        'bar.xml'  => '5/1',
        'bar.json' => '6/1',
        'blah'     => '3/2',
        'black'    => '3/3',
      }

      variations.each do |k,v|
        get k
        is(v).current_body?
      end
    end

  end
end
