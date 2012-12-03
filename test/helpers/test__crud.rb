
module EHelpersTest__CRUD

  class Resource

    def initialize
      @objects = {}
    end

    def get id
      @objects[id]
    end

    def create object
      if obj_id = object.delete('id')
        object[:id] = obj_id
      end
      id = (@objects.size + 1).to_s
      @objects[id] = object.update('__id__' => id)
    end

    def delete id
      @objects.delete id
    end

    def [] key
      @objects[key]
    end

    def keys
      @objects.keys
    end
  end

  class ResourceWithErrors < Resource
    def create object
      id = (@objects.size + 1).to_s
      @objects[id] = HashWithErrors[object.merge('__id__' => id)]
    end

    class HashWithErrors < Hash
      def errors
        error = 'someErrorOccurred'
        # alternating returned error type 
        # cause various resources may throw errors of various types
        rand(1000) % 2 == 0 ? 
          [error]           :
          rand(1000) % 2 == 0 ? {:error => [error]} : error
      end
    end
  end

  RESOURCE = Resource.new
  PRIVATE_RESOURCE = Resource.new

  class App < E
    map '/'

    crudify = lambda do |obj|
      case
        when rq.post?, rq.put?, rq.patch?
          obj['__id__']
        when rq.head?
          response.headers['Last-Modified'] = params[:lm]
        else
          obj.inspect
      end
    end

    crudify RESOURCE, :exclude => ['excluded_param', 'skip_this'], &crudify
    crudify PRIVATE_RESOURCE, :private, &crudify

    setup :post_private, :put_private, :patch_private, :delete_private do
      auth do |u, p|
        [u, p] == ['user', 'pass']
      end
    end
  end

  Spec.new App do

    def update request_method
      lambda do
        key    = RESOURCE.keys.last
        record = RESOURCE[key].dup
        name   = rand.to_s

        send request_method, key, :name => name, :excluded_param => 'blah', :skip_this => 'doh'

        updated_record = RESOURCE[last_response.body]
        expect(updated_record).is_a? Hash
        refute(updated_record['name']) == record['name']
        is(updated_record['excluded_param']).nil?
        is(updated_record['skip_this']).nil?
      end
    end

    Testing :public_CRUD do
      map App.base_url

      Test 'create and update' do
        Should 'create new records' do
          0.upto(5).each do
            name = rand.to_s
            rsp = post :name => name
            id = rsp.body
            is(id.to_i) > 0
          end

          And 'update last record by PUT', &update(:put)
          And 'update last record by PATCH', &update(:patch)
        end
      end

      Test :get do
        RESOURCE.keys.each do |key|
          rsp = get key
          data = eval(rsp.body) rescue nil
          expect(data).is_a?(Hash)
          expect(data['name']) == RESOURCE[key]['name']
        end
      end

      Test :head do
        RESOURCE.keys.each do |key|
          last_modified = Time.now.rfc2822.to_s
          rsp = head key, :lm => last_modified
          expect(rsp.body) == ''
          expect(rsp.header['Last-Modified']) == last_modified
        end
      end

      Test :delete do
        RESOURCE.keys.each do |key|
          delete key
          expect(last_response.status) == 200
        end
        expect(RESOURCE.keys.size) == 0
      end

      Test :options do
        rsp = options
        expect(rsp.body) == 'GET, POST, PUT, HEAD, DELETE, OPTIONS, PATCH'
      end

    end

    Testing :private_CRUD do

      map App.route :private

      Test :options do
        rsp = options
        expect(rsp.body) == 'GET, HEAD, OPTIONS'

        authorize 'user', 'pass'
        rsp = options
        expect(rsp.body) == 'GET, POST, PUT, HEAD, DELETE, OPTIONS, PATCH'
      end

      reset_app!

      Should 'require authorization on C/U/D' do

        rsp = post
        expect(rsp.status) == 401

        rsp = put rand
        expect(rsp.status) == 401

        rsp = patch rand
        expect(rsp.status) == 401

        rsp = delete rand
        expect(rsp.status) == 401

      end

      Should 'grant access and create items' do

        authorize 'user', 'pass'

        Should 'create an item' do
          name = rand.to_s
          rsp = post :name => name
          id = rsp.body
          is(id.to_i) > 0

          Then 'update created item' do
            new_name = rand.to_s
            patch id, :name => new_name

            rsp = get id
            data = eval(rsp.body) rescue nil
            expect(data).is_a?(Hash)
            false?(data['name']) == name

            And 'finally delete it' do
              delete id
              expect(last_response.status) == 200
              expect(PRIVATE_RESOURCE.keys.size) == 0
            end

          end
        end
      end

    end
  end

  class DefaultPrimaryKey < E
    map :/

    crudify Resource.new
  end

  class CustomPrimaryKey < E
    map :/

    crudify Resource.new, :pkey => 'obj_id'
  end

  class BuiltinErrorHandler < E
    map :/

    crudify ResourceWithErrors.new
  end

  class BuiltinErrorHandlerWithCustomStatusCode < E
    map :/

    crudify ResourceWithErrors.new, :halt_with => 501
  end

  Spec.new self do

    Testing DefaultPrimaryKey do
      app DefaultPrimaryKey.mount

      obj_id = rand(1000).to_s
      post :id => obj_id
      expect(last_response.status) == 200
      check(last_response.body) == obj_id
    end

    Testing CustomPrimaryKey do
      app CustomPrimaryKey

      obj_id = rand(1000).to_s
      post :obj_id => obj_id
      expect(last_response.status) == 200
      check(last_response.body) == obj_id
    end

    Testing BuiltinErrorHandler do
      app BuiltinErrorHandler

      post :foo => :bar
      is(last_response.status) == 500
      does(last_response.body) =~ /someErrorOccurred/
    end

    Testing BuiltinErrorHandlerWithCustomStatusCode do
      app BuiltinErrorHandlerWithCustomStatusCode
      
      post :foo => :bar
      is(last_response.status) == 501
      expect(last_response.body) =~ /someErrorOccurred/
    end

  end

end










