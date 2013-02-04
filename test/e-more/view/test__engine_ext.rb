module EMoreTest__View__EngineExt
  class EngineExtTest < E
    map :engine_ext_test
    view_prefix base_url

    engine_ext '.xhtml'

    format '.html'
    format_for :custom___ext, '.xml'

    setup :slim do
      engine :Slim
      engine_ext '.slm'
    end

    def custom___ext
      render
    end

    def slim
      render
    end

    def blah
      engine_ext '.xml.str'
      render
    end

  end

  Spec.new EngineExtTest do

    Ensure 'extension can be set directly on controller' do
      get 'custom-ext'
      expect(last_response.body) == '.xhtml'
    end

    Ensure 'extension can be set inside setup block' do
      get :slim
      expect(last_response.body) == 'slim//.slm'
    end

    Ensure 'extension can be set inside action' do
      get :blah
      expect(last_response.body) == 'blah.xml.str'
    end

    Ensure 'format prepended to extension when format used' do
      get 'slim.html'
      expect(last_response.body) == 'slim/.html/.slm'

      get 'custom-ext.xml'
      expect(last_response.body) == '.xml/.xhtml'
    end
  end
end
