module EGeneratorTest__Ctrl
  Spec.new self do

    project = 'App'

    Testing do

      check { 
        EspressoGenerator.new(GENERATOR__DST_ROOT, false).
          generate(:project, project) 
      }.is_true

      Context 'creating controllers' do

        g = EspressoGenerator.new(GENERATOR__DST_ROOT + project, false)
        Should 'create a controller without route' do
          check(g).generate :controller, 'Pages'
          
          is(File).directory? g.dst_path(:controllers, 'pages')
          file = g.dst_path(:controllers, 'pages.rb')
          is(File).file? file
          expect(File.read file) =~ /class\s+Pages\s+<\s+E[\n|\s]+def/m
        end

        Should 'create a controller with route' do
          check(g).generate :controller, 'News', 'n'
          
          is(File).directory? g.dst_path(:controllers, 'news')
          file = g.dst_path(:controllers, 'news.rb')
          is(File).file? file
          expect(File.read file) =~ /class\s+News\s+<\s+E[\n|\s]+map\s+\Wn/m
        end

      end
    end

    FileUtils.rm_rf(GENERATOR__DST_ROOT + project)

  end
end
