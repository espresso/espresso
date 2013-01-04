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
    def check_variations(variations)
      variations.each do |args|
        self.send(args[0], *args[1])
        is_ok_body? args[2]
      end
    end
  end

  Spec.new self do
    include Hlp
    app(App.mount '/', '/a')

    it "base_url" do
      variations = [
        [:get, [:index], '/index'],
        [:get, [], '/'],
        [:post, [:eatme], '/eatme'],
      ]

      check_variations(variations)
    end

    it "controller_canonicals" do
      variations = [
        [:get, [:cms, :index], '/cms/index'],
        [:get, [:cms], '/cms'],
        [:post, [:cms, :eatme], '/cms/eatme'],
        [:get, [:pages, :index], '/pages/index'],
        [:get, [:pages], '/pages'],
        [:post, [:pages, :eatme], '/pages/eatme'],
      ]

      check_variations(variations)
    end

  end

  Spec.new self do
    include Hlp
    app(App.mount '/', '/a')

    Testing :app_canonicals do
      variations = [
        [:get, [:a], '/a'],
        [:get, [:a, :cms], '/a/cms'],
        [:get, [:a, :cms, :index], '/a/cms/index'],
        [:get, [:a, :pages, :index], '/a/pages/index'],
        [:get, [:a, :pages], '/a/pages'],
        [:post, [:a, :pages, :eatme], '/a/pages/eatme'],
      ]

      check_variations(variations)
    end

  end
end
