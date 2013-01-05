module ECoreTest__LastModified

  class App < E

    def index
      last_modified time_for(params[:time])
    end

  end

  Spec.new App do

    def has_correct_header response, time
      prove(response.headers['Last-Modified']) == time
    end

    def time
      @time ||= (Time.now - 100).httpdate
    end

    Testing do
      get :time => time
      is(last_response).ok?
      does(time).match_last_modified_header?

      ims = (Time.now - 110).httpdate
      header['If-Modified-Since'] = ims

      get :time => time
      is(last_response).ok?
      does(time).match_last_modified_header?
    end

    It 'returns 304 code cause If-Modified-Since header is set to a later time' do
      ims = (Time.now - 90).httpdate
      header['If-Modified-Since'] = ims

      get :time => time
      is( 304).current_status?
      does(time).match_last_modified_header?
    end

    It 'returns 412 code cause If-Unmodified-Since header is set to a time in future' do
      ims = (Time.now - 110).httpdate

      headers.clear
      header['If-Unmodified-Since'] = ims

      get :time => time
      is( 412).current_status?
      expect(last_response.status) == 412
      does(time).match_last_modified_header?
    end

  end
end
