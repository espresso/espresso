module ECoreTest__Accept

  class App < E

    def index field
      meth = field == 'accept' ? field : 'accept_' + field
      self.send meth.to_sym
    end

    def match field
      params[:val] && !params[:val].empty? && params[:val] == index(field) &&
          self.send((field == 'accept' ? field : 'accept_' + field) + '?', params[:val]) &&
          index(field)
    end

  end

  Spec.new App do

    Testing 'content type' do
      field, val = 'accept', Rack::Mime::MIME_TYPES.fetch('.txt')
      headers['Accept'] = val
      get :index, field
      is?(last_response.body) == val
      get :match, field, :val => val
      is?(last_response.body) == val
    end

    Testing 'charset' do
      field, val = 'charset', 'UTF-32'
      headers['Accept-Charset'] = val
      get field
      is?(last_response.body) == val
      get :match, field, :val => val
      is?(last_response.body) == val
    end

    Testing 'encoding' do
      field, val = 'encoding', 'gzip'
      headers['Accept-Encoding'] = val
      get field
      is?(last_response.body) == val
      get :match, field, :val => val
      is?(last_response.body) == val
    end

    Testing 'language' do
      field, val = 'language', 'en-gb'
      headers['Accept-Language'] = val
      get field
      is?(last_response.body) == val
      get :match, field, :val => val
      is?(last_response.body) == val
    end

    Testing 'ranges' do
      field, val = 'ranges', 'bytes'
      headers['Accept-Ranges'] = val
      get field
      is?(last_response.body) == val
      get :match, field, :val => val
      is?(last_response.body) == val
    end

  end
end
