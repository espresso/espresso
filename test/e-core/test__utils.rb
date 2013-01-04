module ECoreTest__Utils
  Spec.new self do
    testing 'rootify_url' do
      variations = [
        [["/", "/main"], "/main"],
        [["/main", "/second"], "/main/second"],
        [["main", "second"], "/main/second"]
      ]

      variations.each do |variation|
        is?(EspressoFrameworkUtils::rootify_url(*variation[0])) == variation[1]
      end
    end

    testing 'underscore' do
      variations = [
        ["SuperClass", "super_class"]
      ]

      variations.each do |variation|
        is?(EspressoFrameworkUtils::underscore(variation[0])) == variation[1]
      end
    end

    testing "demodulize" do
      module Inner
        class TestClass
        end
      end

      is?(EspressoFrameworkUtils::demodulize(Inner::TestClass)) == "TestClass"
    end

    testing "build_path" do
      # shouldn't this be  "some/page?and=some_param" ?
      variations = [
        [[:some, :page, {:and => :some_param}], "some/page?and"],
        [['another', 'page', {:with => {'nested' => 'params'}}], "another/page?with[nested]=params"],
        [['page', {:with => 'param-added', :an_ignored_param => nil}], "page/?with=param-added"],
      ]
      variations.each do |variation|
        res = EspressoFrameworkUtils.build_path(*variation[0])
        is?(res) == variation[1]
      end
    end
  end
end