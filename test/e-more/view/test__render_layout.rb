module EMoreTest__View__RenderLayout
  class App < E
    class Sandbox
      attr_reader :params

      def initialize params = {}
        @params = params
      end
    end

    format '.html'

    setup :index do
      layout :layout
    end
    setup 'index.html' do
      layout :layout__format
    end

    setup :falselayout do
      layout false
    end

    setup /custom_context/ do
      layout :layout__custom_context
    end

    setup /custom_locals/ do
      layout :layout__custom_locals
    end

    setup /inline/ do
      layout { 'Hello <%= yield %>!' }
    end

    def index
      render_layout { 'World' }
    end

    def explicit_layout action
      layout = (f = params[:format]) ? action + f : action.to_sym
      render_layout layout do
        'World'
      end
    end

    def layoutless
      render_layout
    end
    def falselayout
      render_layout
    end

    def implicit_layout_with_custom_context
      render_layout Sandbox.new(params[:sandbox_params])
    end
    def explicit_layout_with_custom_context layout
      render_layout layout, Sandbox.new(params[:sandbox_params])
    end

    def implicit_layout_with_custom_locals
      render_layout params
    end
    def explicit_layout_with_custom_locals layout
      render_layout layout, params
    end

    def implicit_layout_with_inline_template
      render_layout { 'World' }
    end
    def explicit_layout_with_inline_template layout
      render_layout(layout) { 'World' }
    end

  end

  Spec.new App do

    Should 'render format-less layout' do
      expect(get.body) == 'Hello World!'
    end
    Should 'render format-related layout' do
      expect(get('index.html').body) == '.html layout/World'
    end

    Should 'render given layout' do
      expect(get( :explicit_layout, :layout ).body) == 'Hello World!'
    end

    Testing 'inline layout' do
      is?(get(:implicit_layout_with_inline_template).body) == 'Hello World!'
      is?(get(:explicit_layout_with_inline_template, :layout).body) == 'Hello World!'
    end

    Should 'raise error' do
      When 'action has no layout' do
        expect { get :layoutless }.to_raise_error 'No explicit layout given nor implicit layout found'
      end
      When 'action layout set to false' do
        expect { get :falselayout }.to_raise_error 'No explicit layout given nor implicit layout found'
      end
      When 'given layout does not exists' do
        expect { get :explicit_layout, :Blah! }.to_raise_error Errno::ENOENT
      end
    end

    Should 'render the layout of current action within custom context' do
      get :implicit_layout_with_custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      expect(last_response.body) == 'layout-foo=bar;layout-sensitive_data=;'
    end
    Should 'render the layout of given action within custom context' do
      get :explicit_layout_with_custom_context, :layout__custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      expect(last_response.body) == 'layout-foo=bar;layout-sensitive_data=;'
    end

    Should 'render the layout of current action with custom locals' do
      get :implicit_layout_with_custom_locals, 'foo' => 'bar'
      expect(last_response.body) == 'layout-foo=bar;'
    end
    Should 'render the layout of given action with custom locals' do
      get :explicit_layout_with_custom_locals, :layout__custom_locals, 'foo' => 'bar'
      expect(last_response.body) == 'layout-foo=bar;'
    end

  end
end
