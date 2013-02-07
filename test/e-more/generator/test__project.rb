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
        
        Ensure 'database.yml updated' do
          cfg = File.read(G.dst_path(:config, 'database.yml'))
          expect(cfg) =~ /orm\W+#{project}/m
        end
        
        Ensure 'Gemfile updated' do
          gems = File.read(G.dst_path(:root, 'Gemfile'))
          expect(gems) =~ /gem\W+#{project}/m
        end
      end
      cleanup project
    end

  end
end
