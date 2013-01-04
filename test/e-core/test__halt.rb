module ECoreTest__Halt

  class App < E

    def haltme
      args = []
      (status = params['status']) && args << status.to_i
      (body = params['body']) && args << body
      halt *args
    end

    def post_send_response status, body
      halt [status.to_i, request.POST, [body]]
    end

  end

  Spec.new App do

    it 'sending status and body' do
      r = get :haltme, :status => 500, :body => :fatal_error!
      is_status? 500
      is_body? 'fatal_error!'
    end

    it 'accepts empty body' do
      r = get :haltme, :status => 301
      is_redirect? 301
      is_body? ''
    end

    it 'default status code is 200' do
      r = get :haltme, :body => 'halted'
      is_ok_body? 'halted'
    end

    it 'works without arguments' do
      r = get :haltme
      is_ok_body? ''
    end

    it 'custom response' do
      r = post :send_response, 301, 'redirecting...', 'Location' => 'http://to.the.sky'
      is_redirect? 301
      is_body? 'redirecting...'
      is_location? 'http://to.the.sky'
    end

  end
end
