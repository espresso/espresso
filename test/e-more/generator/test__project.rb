module EGeneratorTest__Project
  Spec.new self do

    G = EspressoGenerator.new(GENERATOR__DST_ROOT)
    logger = StringIO.new
    G.logger = Logger.new(logger)

    def cleanup project
      FileUtils.rm_rf G.dst_root + project
    end

    project = 'withoutORM'
    Testing project do
      status = G.generate :project, project
      is(status).true?

      Should 'fail cause project already exists' do
        g = EspressoGenerator.new(GENERATOR__DST_ROOT, false)
        status = g.generate :project, project
        is(status).false?
      end
    end
    cleanup project

    %w[activerecord data_mapper sequel].each do |project|
      Testing project do

        status = G.generate :project, project, project
        is(status).true?
        project_path = G.dst_path(:append => project)

        Ensure 'database.yml updated' do
          expect {
            File.read(project_path[:config] + 'database.yml')
          } =~ /orm\W+#{project}/m
        end
        
        Ensure 'Gemfile updated' do
          expect {
            File.read(project_path[:root] + 'Gemfile')
          } =~ /gem\W+#{project}/m
        end
      end
      cleanup project
    end

  end
end
