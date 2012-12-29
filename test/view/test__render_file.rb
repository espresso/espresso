module EViewTest__File
  class App < E
    map '/'

    format '.xml'
    layout :layout

    engine :ERB
    on '.xml' do
      engine :Slim
    end

    def file
      render_f params[:file]
    end
    def layout_file
      render_lf params[:file] do
        params[:content]
      end
    end

    def slim_file
      render_slim_f params[:file]
    end
    def slim_layout_file
      render_slim_lf params[:file] do
        params[:content]
      end
    end

  end

  Spec.new App do

    Testing :render_file do
      
      Should 'use ERB engine' do
        get :file, :file => 'blah.erb'
        expect(last_response.body) == 'blah.erb - file'
      end

      Should 'use Slim engine' do
        get 'file.xml', :file => 'render_file.slim'
        expect(last_response.body) == '.xml/file'
      end
    end

    Testing :render_layout_file do

      Should 'use ERB engine' do
        get :layout_file, :file => 'layout__format.html.erb', :content => 'Blah!'
        expect(last_response.body) == '.html layout/Blah!'
      end

      Should 'use Slim engine' do
        get 'layout_file.xml', :file => 'render_layout_file.slim', :content => 'Blah!'
        expect(last_response.body) == 'Header|Blah!|Footer'
      end
    end

    Testing :adhoc_rendering do
      Testing :Slim do
        get :slim_file, :file => 'adhoc/slim_file.slim'
        expect(last_response.body) == 'slim_file|slim_file.slim'
        
        get :slim_layout_file, :file => 'adhoc/layouts/slim_layout_file.slim', :content => 'SLIMTEST'
        expect(last_response.body) == 'HEADER|SLIMTEST|FOOTER'

      end
    end

  end
end
