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

    Describe 'sending status and body' do
      r = get :haltme, :status => 500, :body => :fatal_error!
      expect(r.status) == 500
      is?(r.body) == 'fatal_error!'
    end

    Ensure 'it accepts empty body' do
      r = get :haltme, :status => 301
      expect(r.status) == 301
      is?(r.body) == ''
    end

    Ensure 'default status code is 200' do
      r = get :haltme, :body => 'halted'
      expect(r.status) == 200
      is?(r.body) == 'halted'
    end

    Ensure 'it works without arguments' do
      r = get :haltme
      expect(r.status) == 200
      is?(r.body) == ''
    end

    Testing 'custom response' do
      r = post :send_response, 301, 'redirecting...', 'Location' => 'http://to.the.sky'
      expect(r.status) == 301
      expect(r.body) == 'redirecting...'
      is?(r.header['Location']) == 'http://to.the.sky'
    end

  end
end
