module ECoreTest__TransferEncoding

  class App < E

    transfer_encoding '*'

    setup :xml do
      transfer_encoding  'xml'
    end

    format '.json'

    def index
      transfer_encoding('.json') if json?
    end

    def xml
    end

    def json
      transfer_encoding '.json'
    end

    def read something
    end
  end

  Spec.new App do
    Should 'use globally set Transfer-Encoding' do
      get
      is(last_response['Transfer-Encoding']) == '*'

      get :read, :someBook
      is(last_response['Transfer-Encoding']) == '*'
    end

    Should 'use Transfer-Encoding set inside action' do
      get 'index.json'
      is(last_response['Transfer-Encoding']) == '.json'
      
      get 'json'
      is(last_response['Transfer-Encoding']) == '.json'
    end

    Should 'use Transfer-Encoding set via setup block' do
      get :xml
      is(last_response['Transfer-Encoding']) == 'xml'
    end

  end
end
