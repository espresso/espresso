module ECoreTest__ContentType

  class App < E

    content_type '.txt'

    setup :xml do
      content_type  '.xml'
    end

    setup :readme do
      content_type 'readme'
    end

    format '.json'

    def index
      content_type('Blah!') if json?
    end

    def xml
    end

    def json
      content_type '.json'
    end

    def read something

    end

    def readme

    end

  end

  Spec.new App do
    variations = [
      [[], '.txt'],
      [[:xml], '.xml'],
      [[:read, 'feed.json'], '.json'],
      [[:json], '.json'],
      [[:readme], 'readme'], #type set by `content_type` is overridden by type set by format
      [['readme.json'], '.json'],
      [['index.json'], 'Blah!'], # setup by giving action name along with format
    ]

    variations.each do |args|
      get *args[0]
      is(args[1]).current_content_type?
    end
  end
end
