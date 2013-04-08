module ECoreTest__Utils
  Spec.new self do
    Testing 'rootify_url' do
      variations = [
        [["/", "/main"], "/main"],
        [["/main", "/second"],          "/main/second"],
        [["main", "second"],            "/main/second"],
        ['path',                        '/path'],
        ['///some-path/',               '/some-path'],
        [['/some', '/path/'],           '/some/path'],
        [['some', 'another', 'path/'],  '/some/another/path'],
      ]
      variations.each do |variation|
        is?(EUtils.rootify_url(*variation[0])) == variation[1]
      end
    end

    Testing :underscore do
      variations = [
        ["SuperClass", "super_class"],
        ["One1Two2", "one1_two2"]
      ]
      variations.each do |variation|
        check(EUtils.underscore(variation[0])) == variation[1]
      end
    end

    Testing :class_to_route do
      variations = [
        ["SuperClass", "/super_class"],
        ["Super::Class", "/super/class"],
        ["Super::SubClass", "/super/sub_class"],
        ["One1Two2", "/one1_two2"]
      ]
      variations.each do |variation|
        check(EUtils.class_to_route(variation[0])) == variation[1]
      end
    end

    Testing :build_path do
      variations = [
        [[:some, :page, {:and => :some_param}], "some/page?and"],
        [['another', 'page', {:with => {'nested' => 'params'}}], "another/page?with[nested]=params"],
        [['page', {:with => 'param-added', :an_ignored_param => nil}], "page?with=param-added"],
      ]
      variations.each do |variation|
        check(EUtils.build_path(*variation[0])) == variation[1]
      end
    end
  end
end
