module ECoreTest__Alias

  class App < E
    map '/', '/cms'

    def news
      [__method__, action].inspect
    end

    alias :news____html :news
    alias :headlines__recent____html :news

  end

  Spec.new App do

    r = get :news
    expect(r.status) == 200
    is(r.body) == '[:news, :news]'

    r = get 'news.html'
    is(r.body) == '[:news, :news____html]'
    expect(r.status) == 200

    r = get 'headlines/recent.html'
    is(r.body) == '[:news, :headlines__recent____html]'
    expect(r.status) == 200

    Testing 'canonical aliases' do
      r = get :cms, :news
      expect(r.status) == 200
      is(r.body) == '[:news, :news]'

      r = get :cms, 'news.html'
      is(r.body) == '[:news, :news____html]'
      expect(r.status) == 200

      r = get :cms, :headlines, 'recent.html'
      is(r.body) == '[:news, :headlines__recent____html]'
      expect(r.status) == 200
    end

  end
end
