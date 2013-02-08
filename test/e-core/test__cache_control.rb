module ECoreTest__CacheControl

  GENERIC = [:public, :must_revalidate, {:max_age => 600}]
  PRIVATE = [:private, :proxy_revalidate, {:min_stale => 20}]
  INLINE = [:no_cache, :no_store, {:s_max_age => 500}]
  XML = [:no_store, :must_revalidate, {:max_age => 100, :s_max_age => 200}]

  class App < E
    format '.xml'

    cache_control *GENERIC

    setup :private do
      cache_control *PRIVATE
    end

    setup '.xml' do
      cache_control *XML
    end

    def index

    end

    def private

    end

    def read something

    end

    def inline
      cache_control *INLINE
    end

  end

  Spec.new App do

    def contain_correct_header? response, *directives
      is?(response.headers['Cache-Control']) ==
          App.new(:index).cache_control(*directives)
    end

    get
    does(last_response).contain_correct_header? *GENERIC

    get :private
    does(last_response).contain_correct_header? *PRIVATE

    get :inline
    does(last_response).contain_correct_header? *INLINE

    get 'index.xml'
    does(last_response).contain_correct_header? *XML

    get :read, 'book.xml'
    does(last_response).contain_correct_header? *XML

  end
end
