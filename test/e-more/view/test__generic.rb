module EMoreTest__View__Generic

  class GenericTest < E
    class Sandbox
      attr_reader :params

      def initialize params = {}
        @params = params
      end
    end

    map :generic_test
    view_prefix base_url
    engine :ERB
    layout :layout
    format_for :custom___ext, '.xml'

    setup /custom_context/ do
      layout :layout__custom_context
    end

    setup /custom_locals/ do
      layout :layout__custom_locals
    end

    setup :custom___ext do
      engine_ext '.xhtml'
    end

    def index
      @greeting = 'World'
      render
    end

    def get_partial
      render_partial
    end

    def render_given template
      render template
    end

    def render_given_partial template
      render_partial template
    end

    def some___action
      'some string'
    end

    def templateless_action
      render
    end

    def implicit_template_with_custom_context
      render Sandbox.new(params[:sandbox_params])
    end

    def explicit_template_with_custom_context template
      render template, Sandbox.new(params[:sandbox_params])
    end

    def implicit_template_with_custom_locals
      render params
    end

    def explicit_template_with_custom_locals template
      render_partial template, params
    end

    def inline
      render { render_partial { 'World' } }
    end

    def inline_partial
      render_partial { 'World' }
    end

    def custom___ext
      render_partial
    end

  end

  Spec.new GenericTest do

    Should 'render template of current action with layout' do
      get
      is('Hello World!').current_body?
    end
    
    Should 'render template of current action without layout' do
      get :partial
      is('get_partial').current_body?
    end

    Should 'correctly resolve path for given template' do
      And 'render with layout' do
        get :render_given, :some___action
        is('Hello render_given!').current_body?
      end
      And 'render without layout' do
        get :render_given_partial, :some___action
        is('render_given_partial').current_body?
      end
    end

    Testing 'inline rendering' do
      Should 'render with layout' do
        expect(get(:inline).body) == 'Hello World!'
      end
      And 'without layout' do
        expect(get(:inline_partial).body) == 'World'
      end
    end

    Testing 'extension' do
      expect(get('custom-ext').body) == '.xhtml'

      Should 'prepend format to engine ext' do
        expect(get('custom-ext.xml').body) == '.xml/.xhtml'
      end
    end

    Should 'raise error' do
      When 'non-existing action/template given' do
        expect { get :render_given, :blah! }.to_raise_error
      end
      When 'given action has no template' do
        expect { get :templateless_action }.to_raise_error
      end
    end

    Should 'render template of current action within custom context' do
      get :implicit_template_with_custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      is('layout-foo=bar;layout-sensitive_data=;foo=bar;sensitive_data=').current_body?
    end
    Should 'render given template within custom context' do
      get :explicit_template_with_custom_context, :implicit_template_with_custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      is('layout-foo=bar;layout-sensitive_data=;foo=bar;sensitive_data=').current_body?
    end

    Should 'render current action with custom locals' do
      get :implicit_template_with_custom_locals, 'foo' => 'bar'
      is('layout-foo=bar;foo=bar').current_body?
    end
    Should 'render given action with custom locals' do
      get :explicit_template_with_custom_locals, :implicit_template_with_custom_locals, 'foo' => 'bar'
      is('foo=bar').current_body?
    end

  end
end
