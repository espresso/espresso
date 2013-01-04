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

    testing do
      get :time => time
      is_ok?
      is_last_modified?(time)

      ims = (Time.now - 110).httpdate
      header['If-Modified-Since'] = ims

      get :time => time
      is_ok?
      is_last_modified?(time)
    end

    it 'returns 304 code cause If-Modified-Since header is set to a later time' do
      ims = (Time.now - 90).httpdate
      header['If-Modified-Since'] = ims

      get :time => time
      is_status? 304
      is_last_modified?(time)
    end

    it 'returns 412 code cause If-Unmodified-Since header is set to a time in future' do
      ims = (Time.now - 110).httpdate

      headers.clear
      header['If-Unmodified-Since'] = ims

      get :time => time
      is_status? 412
      expect(last_response.status) == 412
      is_last_modified?(time)
    end

  end
end
