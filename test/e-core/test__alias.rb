module ECoreTest__Alias

  class AliasApp < E
    map '/', '/cms'

    def news
      [__method__, action].inspect
    end

    alias :news____html :news
    alias :headlines__recent____html :news

  end

  Spec.new AliasApp do

    testing do
      get :news
      is_ok_body? '[:news, :news]'

      get 'news.html'
      is_ok_body? '[:news, :news____html]'

      get 'headlines/recent.html'
      is_ok_body? '[:news, :headlines__recent____html]'
    end

    testing 'canonical aliases' do
      get :cms, :news
      is_ok_body? '[:news, :news]'

      get :cms, 'news.html'
      is_ok_body? '[:news, :news____html]'

      get :cms, :headlines, 'recent.html'
      is_ok_body? '[:news, :headlines__recent____html]'
    end
  end
end
