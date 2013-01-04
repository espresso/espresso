module ECoreTest__Utils
  Spec.new self do
    it 'rootify_url' do
      variations = [
        [["/", "/main"], "/main"],
        [["/main", "/second"], "/main/second"],
        [["main", "second"], "/main/second"]
      ]

      variations.each do |variation|
        is?(EspressoFrameworkUtils::rootify_url(*variation[0])) == variation[1]
      end
    end

    it 'underscore' do
      variations = [
        ["SuperClass", "super_class"]
      ]

      variations.each do |variation|
        is?(EspressoFrameworkUtils::underscore(variation[0])) == variation[1]
      end
    end

    it "demodulize" do
      module Inner
        class TestClass
        end
      end

      is?(EspressoFrameworkUtils::demodulize(Inner::TestClass)) == "TestClass"
    end

    it "build_path" do
      # shouldn't this be  "some/page?and=some_param" ?
      variations = [
        [[:some, :page, {:and => :some_param}], "some/page?and"],
        [['another', 'page', {:with => {'nested' => 'params'}}], "another/page?with[nested]=params"],
        [['page', {:with => 'param-added', :an_ignored_param => nil}], "page?with=param-added"],
      ]
      variations.each do |variation|
        res = EspressoFrameworkUtils.build_path(*variation[0])
        is?(res) == variation[1]
      end
    end
  end
end