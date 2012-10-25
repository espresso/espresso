EViewTest__Setup__SliceSetup = lambda do

  engine :Erubis
  engine_ext '.xHTML'
  layout 'slice'

  view_path! 'slice'
  layouts_path! 'slice'

  setup :overridden do
    engine! :Liquid
    engine_ext! '.Liquid'
    layout! 'overridden_by_slice'
  end

end

module EViewTest__SetupByController

  class App < E

    engine :Haml
    engine_ext '.HAML'
    layout 'controller'

    view_path 'controller'
    layouts_path 'controller'

    setup :overridden do
      engine :ERB
      engine_ext '.ERB'
      layout 'set_by_controller'
    end

  end

  Spec.new self do
    app App.mount &EViewTest__Setup__SliceSetup
    get

    Testing :engine do
      expect(App.engine?.first) == Tilt::HamlTemplate
      Ensure 'it is overridden by slice for :overridden action' do
        expect(App.engine?(:overridden).first) == Tilt::LiquidTemplate
      end
    end

    Testing :engine_ext do
      expect(App.engine_ext?) == '.HAML'
      Ensure 'it is overridden by slice for :overridden action' do
        expect(App.engine_ext?(:overridden)) == '.Liquid'
      end
    end

    Testing :layout do
      expect(App.layout?.first) == 'controller'
      Ensure 'it is overridden by slice for :overridden action' do
        expect(App.layout?(:overridden).first) == 'overridden_by_slice'
      end
    end

    Testing :view_path do
      Ensure 'it is overridden by slice' do
        expect(App.view_path?) =~ /slice\/\Z/
      end
    end

    Testing :layouts_path do
      Ensure 'it is overridden by slice' do
        expect(App.layouts_path?) == 'slice/'
      end
    end

  end

end

module EViewTest__SetupBySlice

  class App < E

  end

  Spec.new self do
    app App.mount &EViewTest__Setup__SliceSetup
    get

    expect(App.engine?.first) == Tilt::ErubisTemplate

    expect(App.engine_ext?) == '.xHTML'
    expect(App.layout?.first) == 'slice'
    expect(App.view_path?) =~ /slice\/\Z/
    expect(App.layouts_path?) == 'slice/'

  end

end
