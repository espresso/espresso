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
    Testing do
      get :news
      is('[:news, :news]').ok_body?

      get 'news.html'
      is('[:news, :news____html]').ok_body?

      get 'headlines/recent.html'
      is('[:news, :headlines__recent____html]').ok_body?
    end

    Testing 'canonical aliases' do
      get :cms, :news
      is('[:news, :news]').ok_body?

      get :cms, 'news.html'
      is('[:news, :news____html]').ok_body?

      get :cms, :headlines, 'recent.html'
      is('[:news, :headlines__recent____html]').ok_body?
    end
  end
end
