module EMoreTest__View__File
  class RenderFileTest < E
    map '/'

    format '.xml', '.json'
    layout :layout

    engine :ERB
    on '.xml' do
      engine :Slim
    end
    on '.json' do
      engine :Rabl
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

    def rabl_file
      render_rabl_f params[:file]
    end

  end

  Spec.new RenderFileTest do

    Testing :render_file do
      
      Should 'use ERB engine' do
        get :file, :file => 'blah.erb'
        expect(last_response.body) == 'blah.erb - file'
      end

      Should 'use Slim engine' do
        get 'file.xml', :file => 'render_file.slim'
        expect(last_response.body) == '.xml/file'
      end

      Should 'use Rabl engine' do
        # NOTE: Rabl internally implements a format helper so instead it
        # provides request_format which does not contain a preceeding '.'
        get 'file.json', :file => 'render_file.rabl'
        expect(last_response.body) == '{"format":"json","action":"file"}'
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
        get :slim_file, :file => 'adhoc_test/slim_file.slim'
        expect(last_response.body) == 'slim_file|slim_file.slim'
        
        get :slim_layout_file, :file => 'adhoc_test/layouts/slim_layout_file.slim', :content => 'SLIMTEST'
        expect(last_response.body) == 'HEADER|SLIMTEST|FOOTER'

      end

      Testing :Rabl do
        get :rabl_file, :file => 'adhoc_test/rabl_file.rabl'
        expect(last_response.body) == '{"action":"rabl_file","file":"rabl_file.rabl"}'
      end
    end

  end
end
