module EGeneratorTest__Ctrl
  Spec.new self do

    project = 'App'

    Testing do

      g = EspressoGenerator.new(GENERATOR__DST_ROOT, false)
      check( g.generate(:project, project) ).is_true

      Context 'creating controllers' do

        Should 'create a controller without route' do
          g.generate :controller, 'Pages'
          expect( File.file?(g.dst_path(:controllers, 'pages.rb'))).is_true
        end
      end
    end

    FileUtils.rm_rf(GENERATOR__DST_ROOT + project)

  end
end
