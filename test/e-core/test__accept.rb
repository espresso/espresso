module ECoreTest__Accept

  class AcceptApp < E

    def match field
      meth = (field == 'accept' ? field : 'accept_' + field) + '?'
      request.send(meth, params[:val])
    end

  end

  Spec.new AcceptApp do

    testing 'content type' do
      field, val = 'accept', Rack::Mime::MIME_TYPES.fetch('.txt')
      headers['Accept'] = val

      get :match, field, :val => val
      is_body? val
    end

    testing 'charset' do
      field, val = 'charset', 'UTF-32'
      headers['Accept-Charset'] = val

      get :match, field, :val => val
      is_body? /#{val}/
    end

    testing 'encoding' do
      field, val = 'encoding', 'gzip'
      headers['Accept-Encoding'] = val

      get :match, field, :val => val
      is_body? /#{val}/
    end

    testing 'language' do
      field, val = 'language', 'en-gb'
      headers['Accept-Language'] = val

      get :match, field, :val => val
      is_body? /#{val}/
    end

    testing 'ranges' do
      field, val = 'ranges', 'bytes'
      headers['Accept-Ranges'] = val

      get :match, field, :val => val
      is_body? /#{val}/
    end

  end
end