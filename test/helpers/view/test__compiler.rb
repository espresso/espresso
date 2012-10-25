module EViewTest__Compiler
  class App < E
    map '/'

    before do
      if key = params[:__clear_compiler__]
        key == '*' ? clear_compiler! : clear_compiler!(key)
      end
    end

    layout :layout

    def index file
      unless params[:__clear_compiler__]
        render '' => true do
          render_partial file, '' => file
        end
      end
    end

    def threaded file
      unless params[:__clear_compiler__]

        o = nil
        Thread.new do
          o = render '' => true do
            render_partial file, '' => file
          end
        end.join
        o
      end
    end

    def clear_compiler_like_array
      compiler_key = ['clear' ,'compiler' ,'like' ,'array']
      
      # pushing to pool
      render_partial :clear_compiler_test, '' => compiler_key

      if keys = params[:keys]
        # clearing pool
        clear_compiler_like! keys
      end

      self.class.app.compiler_pool.keys.select { |k| k.first == compiler_key }.size > 0
    end

    def clear_compiler_like_regexp
      compiler_key = 'clear_compiler_like_regexp'
      
      # pushing to pool
      render_partial :clear_compiler_test, '' => compiler_key

      if key = params[:key]
        # clearing pool
        clear_compiler_like! /#{key}/
      end

      self.class.app.compiler_pool.keys.select { |k| k.first == compiler_key }.size > 0
    end

  end

  Spec.new App do

    def file content
      file = rand.to_s
      path = App.view_fullpath? + file +
          (App.engine_ext? || App.engine_default_ext?(App.engine?.first))
      ::File.open(path, 'w') { |f| f << content }
      [file, path]
    end

    file, path = file('World')

    r = get file
    ::File.unlink path
    is?(r.body) == 'Hello World!'

    Should 'return same result after file deleted' do
      expect { ::File.read path }.raise_error

      r = get file
      is?(r.body) == 'Hello World!'
    end

    Should 'clear compiler and raise an error on render' do
      get file, :__clear_compiler__ => '*'
      expect { get file }.raise_error
    end

    Should 'behave well on threaded scenarios' do

      file, path = file('World')

      r = get :threaded, file
      ::File.unlink path
      is?(r.body) == 'Hello World!'

      Should 'return same result after file deleted' do
        expect { ::File.read path }.raise_error

        r = get :threaded, file
        is?(r.body) == 'Hello World!'
      end

      Should 'clear compiler and raise an error on render' do
        get :threaded, file, :__clear_compiler__ => '*'
        expect { get :threaded, file }.raise_error
      end
    end

    Should 'clear by given array' do
      get :clear_compiler_like_array
      expect(last_response.body) == 'true'
            
      [
        ['clear' ],
        ['clear' ,'compiler'],
        ['clear' ,'compiler' ,'like' ],
        ['clear' ,'compiler' ,'like' ,'array'],
      ].each do |keys|
        get :clear_compiler_like_array, :keys => keys
        expect(last_response.body) == 'false'
      end

      [
        ['clear', 'blah'],
        ['clear' ,'compiler' ,'like', 'blah'],
        ['clear' ,'compiler' ,'like' ,'array', 'yo'],
      ].each do |keys|
        get :clear_compiler_like_array, :keys => keys
        expect(last_response.body) == 'true'
      end
    end

    Should 'clear by given regexp' do

      get :clear_compiler_like_regexp
      expect(last_response.body) == 'true'

      [
        'clear',
        'compiler',
        'like',
        'regexp',
        'clear_compiler',
        'clear_compiler_like',
        'clear_compiler_like_regexp',
      ].each do |key|
        get :clear_compiler_like_regexp, :key => key
        expect(last_response.body) == 'false'
      end
      
      [
        'compiler_clear',
        'like_clear_compiler',
        'regexp_like_clear_compiler',
      ].each do |key|
        get :clear_compiler_like_regexp, :key => key
        expect(last_response.body) == 'true'
      end
    end

  end
end
