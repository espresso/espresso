module ECoreTest__LastModified

  class App < E

    def index
      last_modified! time_for(params[:time])
    end

  end

  Spec.new App do

    def has_correct_header response, time
      prove(response.headers['Last-Modified']) == time
    end

    time = (Time.now - 100).httpdate
    get :time => time
    expect(last_response.status) == 200
    check(last_response).has_correct_header time

    ims = (Time.now - 110).httpdate
    header['If-Modified-Since'] = ims

    get :time => time
    expect(last_response.status) == 200
    check(last_response).has_correct_header time

    Should 'return 304 code cause If-Modified-Since header is set to a later time' do
      ims = (Time.now - 90).httpdate
      header['If-Modified-Since'] = ims

      get :time => time
      expect(last_response.status) == 304
      check(last_response).has_correct_header time
    end

    Should 'return 412 code cause If-Unmodified-Since header is set to a time in future' do
      ims = (Time.now - 110).httpdate

      headers.clear
      header['If-Unmodified-Since'] = ims

      get :time => time
      expect(last_response.status) == 412
      check(last_response).has_correct_header time
    end

  end
end
