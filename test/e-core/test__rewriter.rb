module ECoreTest__Rewriter

  class Cms < E
    map '/'

    rewrite /controller\-redirect/ do
      redirect Cms[:news]
    end
    
    rewrite /controller\-pass\/(.*)/ do |m|
      pass Cms, m.to_sym
    end

    rewrite /controller\-halt\/(\d+)\/(.*)/ do |code,msg|
      halt code.to_i, msg
    end

    def articles *args
      raise 'this action should never be executed'
    end

    def old_news *args
      raise 'this action should never be executed'
    end

    def old_pages *args
      raise 'this action should never be executed'
    end

    def test_pass *args
      [args, params].flatten.inspect
    end

    def news name
      [name, params].inspect
    end

    def page
      params.inspect
    end

    def index(*)
      action_name
    end
  end

  class Store < E
    map '/'

    def buy product
      [product, params]
    end
  end
  Store.mount

  Spec.new self do

    app E.new {

      mount Cms

      rewrite /\A\/articles\/(\d+)\.html$/ do |title|
        redirect '/page?title=%s' % title
      end

      rewrite /\A\/landing\-page\/([\w|\d]+)\/([\w|\d]+)/ do |page, product|
        redirect Store.route(:buy, product, :page => page)
      end

      rewrite /\A\/News\/(.*)\.php/ do |name|
        redirect Cms.route(:news, name, (request.query_string.size > 0 ? '?' << request.query_string : ''))
      end

      rewrite /\A\/old_news\/(.*)\.php/ do |name|
        permanent_redirect Cms.route(:news, name)
      end

      rewrite /\A\/pages\/+([\w|\d]+)\-(\d+)\.html/i do |name, id|
        redirect Cms.route(:page, name, :id => id)
      end

      rewrite /\A\/old_pages\/+([\w|\d]+)\-(\d+)\.html/i do |name, id|
        permanent_redirect "/page?name=#{ name }&id=#{ id }"
      end

      rewrite /\A\/pass_test_I\/(.*)/ do |name|
        pass Cms, :test_pass, name, :name => name
      end

      rewrite /\A\/pass_test_II\/(.*)/ do |name|
        pass Store, :buy, name, :name => name
      end

      rewrite /\A\/halt_test_I\/(.*)\/(\d+)/ do |body, code|
        halt body, code.to_i, 'TEST' => '%s|%s' % [body, code]
        raise 'this shit should not be happen'
      end

      rewrite /\A\/halt_test_II\/(.*)\/(\d+)/ do |body, code|
        halt [code.to_i, {'TEST' => '%s|%s' % [body, code]}, body]
        raise 'this shit should not be happen'
      end

      rewrite /\/context_sensitive\/(.*)/ do |name|
        if request.user_agent =~ /google/
          permanent_redirect Cms.route(:news, name)
        else
          redirect Cms.route(:news, name)
        end
      end

      rewrite /\/pass_next/ do
        pass
        raise
      end
    }

    Testing :redirect do
      page, product = rand(1000000).to_s, rand(1000000).to_s
      get '/landing-page/%s/%s' % [page, product]
      is(last_response).redirected?
      is(last_response).redirected_to? Store.route(:buy, product, :page => page)

      var = rand 1000000
      get '/articles/%s.html' % var
      is(last_response).redirected?
      is(last_response).redirected_to? '/page?title=%s' % var

      var = rand.to_s
      get '/News/%s.php' % var
      is(last_response).redirected?
      is(last_response).redirected_to? '/news/%s/' % var

      var, val = rand.to_s, rand.to_s
      get '/News/%s.php' % var, var => val
      is(last_response).redirected?
      is(last_response).redirected_to? '/news/%s/?%s=%s' % [var, var, val]

      var = rand.to_s
      get '/old_news/%s.php' % var
      is(last_response).redirected_with? 301
      is(last_response).redirected_to? '/news/%s' % var

      name, id = rand(1000000), rand(100000)
      get '/pages/%s-%s.html' % [name, id]
      is(last_response).redirected?
      is(last_response).redirected_to? '/page/%s?id=%s' % [name, id]

      name, id = rand(1000000), rand(100000)
      get '/old_pages/%s-%s.html' % [name, id]
      is(last_response).redirected_with? 301
      is(last_response).redirected_to? '/page?name=%s&id=%s' % [name, id]
    end

    Testing :pass do
      name = rand(100000).to_s
      get '/pass_test_I/%s' % name
      
      is([name, {'name' => name}].inspect).ok_body?
      
      name = rand(100000).to_s
      get '/pass_test_II/%s' % name
      is([name, {'name' => name}].to_s).ok_body?

      Should 'pass control to next matching route' do
        get '/pass_next'
        is('index').current_body?
      end
    end

    Testing :halt do

      body, code = rand(100000).to_s, 500
      response = get '/halt_test_I/%s/%s' % [body, code]
      is(code).current_status?
      is(body).current_body?
      expect(last_response.headers['TEST']) == '%s|%s' % [body, code]

      body, code = rand(100000).to_s, 500
      response = get '/halt_test_II/%s/%s' % [body, code]
      is(code).current_status?
      is(body).current_body?
      expect(last_response.headers['TEST']) == '%s|%s' % [body, code]
    end

    Testing :context do
      name = rand(100000).to_s
      get '/context_sensitive/%s' % name
      is(last_response).redirected?
      follow_redirect!
      is([name, {}].inspect).ok_body?

      header['User-Agent'] = 'google'
      get '/context_sensitive/%s' % name
      is(last_response).redirected_with? 301
      follow_redirect!
      is([name, {}].inspect).ok_body?
    end

    Testing 'rules defined inside controller' do
      get 'controller-redirect'
      is(last_response).redirected?
      is(last_response).redirected_to? '/news'

      get 'controller-pass/page', :foo => :bar
      is(200).current_status?
      is({'foo' => 'bar'}.inspect).current_body?

      get 'controller-halt/201/blah'
      is(201).current_status?
      is('blah').current_body?
    end
  end

  class HostTest < E
    map host: 'foo.bar'
    rewrite /\A\/+(.*)\.html\Z/ do |page|
      halt 200, page
    end
  end

  Spec.new HostTest do

    Should 'listen on default host' do
      get 'blah.html'
      is(last_response).ok?
      is('blah').ok_body?
    end

    Should 'listen on specified hosts' do
      header['HTTP_HOST'] = 'foo.bar'
      get 'blah.html'
      is(last_response).ok?
      is('blah').ok_body?
    end

    Should 'reject foreign hosts' do
      header['HTTP_HOST'] = 'evil.tld'
      get 'blah.html'
      is(last_response).not_found?
    end
  end

end
