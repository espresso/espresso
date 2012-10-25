module ECoreTest__Setup

  SliceSetup = lambda do

    path_rule 'set_by', 'slice'
    path_rule! 'overridden', 'by slice'

    before {}
    after {}

    setup :restricted do
      auth { :set_by_slice__basic }
      digest_auth { :set_by_slice__digest }
    end

    setup :overridden do
      auth! { :overridden_by_slice }
      content_type! 'overridden_by_slice'
      charset! 'overridden_by_slice'
      format! 'overridden_by_slice'
    end

    error(404) { :set_by_slice }
    error!(500) { :overridden_by_slice }

    content_type 'slice'
    charset 'slice'

    format :xml, :json
    setup :blah do
      format :txt
    end

  end

  ControllerSetup = lambda do

    path_rule 'set_by', 'controller'
    path_rule 'overridden', 'by controller'

    before {}
    after {}

    setup :restricted do
      auth { :set_by_controller }
    end

    setup :overridden do
      auth { :set_by_controller }
      content_type 'set_by_controller'
      charset 'set_by_controller'
      format 'set_by_controller'
    end

    error(404) { :set_by_controller }
    error(500) { :set_by_controller }

    content_type 'controller'
    charset 'controller'

    format :test_global
    setup :test_format do
      format :test_local
    end

    setup :a1, :a2 do
      charset 'ISO-8859-2'
    end
    setup :a2 do
      content_type '.js'
    end
  end

  class ControllerTest < E

    self.class_exec &ControllerSetup

    def a1

    end

    def a2

    end

  end

  Spec.new self do
    app ControllerTest.mount(&SliceSetup)
    map ControllerTest.base_url
    get

    Testing :path_rule do
      expect(ControllerTest.path_rules['set_by']) == 'controller'

      Ensure 'path rule overridden by slice' do
        expect(ControllerTest.path_rules['overridden']) == 'by slice'
      end
    end

    Describe 'actions can receive callbacks from slices even if there are ones set by controller' do
      expect(ControllerTest.hooks?(:a).size) == 2
      expect(ControllerTest.hooks?(:z).size) == 2
    end

    Testing :auth do
      expect(ControllerTest.restrictions?(:restricted)[2].call) == :set_by_controller

      Ensure 'auth overridden by slice' do
        expect(ControllerTest.restrictions?(:overridden)[2].call) == :overridden_by_slice
      end
    end

    Testing :error_procs do
      expect(ControllerTest.new.send ControllerTest.error?(404).first) == :set_by_controller

      Ensure '500 code overridden by slice' do
        expect(ControllerTest.new.send ControllerTest.error?(500).first) == :overridden_by_slice
      end

    end

    Testing :content_type do
      expect(ControllerTest.content_type?) == 'controller'

      Ensure 'it is overridden by slice for :overridden action' do
        expect(ControllerTest.content_type?(:overridden)) == 'overridden_by_slice'
      end
    end

    Testing :charset do
      expect(ControllerTest.charset?) == 'controller'

      Ensure 'it is overridden by slice for :overridden action' do
        expect(ControllerTest.charset?(:overridden)) == 'overridden_by_slice'
      end
    end

    Testing :format do
      is?(ControllerTest.format?) == ['.test_global']
      is?(ControllerTest.format? :test_format) == ['.test_local']
      Ensure 'it is overridden by slice for :overridden action' do
        is?(ControllerTest.format? :overridden) == ['.overridden_by_slice']
      end
    end

    Describe 'both a1 and a2 has ISO-8859-2 charset' do

      a1 = get :a1
      expect(a1.headers['Content-Type']) =~ /charset=ISO\-8859\-2/

      a2 = get :a2
      expect(a2.headers['Content-Type']) =~ /charset=ISO\-8859\-2/

      And 'only a2 has js content type' do
        expect(a2.headers['Content-Type']) =~ /javascript/
        refute(a1.headers['Content-Type']) =~ /javascript/
      end
    end

  end


  class SliceTest < E

  end

  Spec.new self do
    app SliceTest.mount(&SliceSetup)
    map SliceTest.base_url
    get

    expect(SliceTest.path_rules['set_by']) == 'slice'

    expect(SliceTest.hooks?(:a).size) == 1
    expect(SliceTest.hooks?(:z).size) == 1

    expect(SliceTest.restrictions?(:restricted)[2].call) == :set_by_slice__basic

    expect(SliceTest.new.send SliceTest.error?(404).first) == :set_by_slice

    expect(SliceTest.content_type?) == 'slice'
    expect(SliceTest.charset?) == 'slice'

    expect(SliceTest.format?) == [".xml", ".json"]
    expect(SliceTest.format? :blah) == [".txt"]

  end

  class LockTest < E

    self.class_exec &ControllerSetup

  end

  Spec.new self do
    app LockTest.mount
    map LockTest.base_url
    get

    expect(LockTest.path_rules['set_by']) == 'controller'
    expect(LockTest.hooks?(:a).size) == 1
    expect(LockTest.hooks?(:z).size) == 1
    expect(LockTest.restrictions?(:restricted)[2].call) == :set_by_controller
    expect(LockTest.new.send LockTest.error?(404).first) == :set_by_controller
    expect(LockTest.content_type?) == 'controller'
    expect(LockTest.charset?) == 'controller'
    expect(LockTest.format?) == ['.test_global']
    expect(LockTest.format? :test_format) == ['.test_local']

    o 'trying to alter setup'
    LockTest.class_exec &SliceSetup

    Ensure 'setup was not altered' do
      expect(LockTest.path_rules['set_by']) == 'controller'
      expect(LockTest.hooks?(:a).size) == 1
      expect(LockTest.hooks?(:z).size) == 1
      expect(LockTest.restrictions?(:restricted)[2].call) == :set_by_controller
      expect(LockTest.new.send LockTest.error?(404).first) == :set_by_controller
      expect(LockTest.content_type?) == 'controller'
      expect(LockTest.charset?) == 'controller'
      expect(LockTest.format?) == ['.test_global']
      expect(LockTest.format? :test_format) == ['.test_local']
    end
  end

  module Forum
    class Users < E

    end
    class Posts < E

    end
  end

  Spec.new self do
    app = Forum.mount do |ctrl|
      case ctrl.name.split('::').last.to_sym
        when :Users
          engine :Haml
          layout :users
        when :Posts
          engine :ERB
          layout :master
      end
    end
    app(app)
    get

    check(Forum::Users.engine?.first) == Tilt::HamlTemplate
    prove(Forum::Users.layout?.first) == 'users'

    try(Forum::Posts.engine?.first) == Tilt::ERBTemplate
    try(Forum::Posts.layout?.first) == 'master'
  end

end
