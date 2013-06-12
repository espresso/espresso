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

    Testing 'sending status and body' do
      r = get :haltme, :status => 500, :body => :fatal_error!
      is(500).current_status?
      is('fatal_error!').current_body?
    end

    It 'accepts empty body' do
      r = get :haltme, :status => 301
      is(last_response).redirected_with? 301
      is('').current_body?
    end

    It 'default status code is 200' do
      r = get :haltme, :body => 'halted'
      is('halted').ok_body?
    end

    It 'works without arguments' do
      r = get :haltme
      is('').ok_body?
    end

    Testing 'custom response' do
      r = post :send_response, 301, 'redirecting...', 'Location' => 'http://to.the.sky'
      is(last_response).redirected_with? 301
      is('redirecting...').current_body?
      is('http://to.the.sky').current_location?
    end

  end
end
