module ECoreTest__Expires

  GENERIC_AMOUNT = 600
  GENERIC = [:public, :must_revalidate]

  PRIVATE_AMOUNT = 20
  PRIVATE = [:private, :proxy_revalidate]

  INLINE_AMOUNT = 500
  INLINE = [:no_cache, :no_store]

  XML_AMOUNT = 200
  XML = [:no_store, :must_revalidate]

  class App < E
    format '.xml'

    expires GENERIC_AMOUNT, *GENERIC

    setup :private do
      expires PRIVATE_AMOUNT, *PRIVATE
    end

    setup '.xml' do
      expires XML_AMOUNT, *XML
    end

    def index
    end

    def private
    end

    def read something
    end

    def inline
      expires INLINE_AMOUNT, *INLINE
    end

  end
  App.mount

  Spec.new App do

    def contain_suitable_headers? response, amount, *directives
      date_format = '%a, %d %b %Y %H:%M:%S %Z'
      cache_control = response.headers['Cache-Control']
      cc = App.new(:index).cache_control(*directives << {:max_age => amount})
      expect(cc) == cache_control

      raw_expires = response.headers['Expires']
      begin
        expires = Time.parse(raw_expires)
      rescue => e
        fail('Received Bad "Expires" Header - %s\n%s' % [raw_expires, e.message])
      end
      check(expires) <= Time.now + amount
    end

    Testing do
      get
      does(last_response).contain_suitable_headers? GENERIC_AMOUNT, *GENERIC

      get :private
      does(last_response).contain_suitable_headers? PRIVATE_AMOUNT, *PRIVATE

      get :inline
      does(last_response).contain_suitable_headers? INLINE_AMOUNT, *INLINE

      get 'index.xml'
      does(last_response).contain_suitable_headers? XML_AMOUNT, *XML

      get :read, 'book.xml'
      does(last_response).contain_suitable_headers? XML_AMOUNT, *XML
    end
  end
end
