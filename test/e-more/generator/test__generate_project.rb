module EGeneratorTest__Project
  Spec.new self do
    include GeneratorSpecHelper
    
    cleanup

    Dir.chdir GENERATOR__DST_ROOT do

      Should 'create a basic project, without any setups' do
        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Should 'fail cause project already exists' do
          output = %x[#{GENERATOR__BIN} g:p App]
          check {$?.exitstatus} > 0
          expect(output) =~ /already\W+exists/
        end
      end
      cleanup

      %w[activerecord data_mapper sequel].each do |orm|
        Testing orm do

          %x[#{GENERATOR__BIN} g:p App orm:#{orm}]
          check {$?.exitstatus} == 0

          Ensure 'config.yml updated' do
            expect {
              File.read 'App/config/config.yml'
            } =~ /orm\W+#{orm}/i
          end
          
          Ensure 'Gemfile updated' do
            expect {
              File.read 'App/Gemfile'
            } =~ /gem\W+#{orm}/i
          end

        end
        cleanup
      end

      %w[Haml Slim].each do |engine|
        Testing engine do

          %x[#{GENERATOR__BIN} g:p App engine:#{engine} format:#{engine}]
          check {$?.exitstatus} == 0

          Ensure 'config.yml updated' do
            cfg = nil
            expect {
              cfg = File.read('App/config/config.yml')
            } =~ /engine\W+#{engine}/i
            expect { cfg } =~ /format\W+#{engine}/
          end
          
          Ensure 'Gemfile updated' do
            expect {
              File.read('App/Gemfile')
            } =~ /gem\W+#{engine}/im
          end

        end
        cleanup
      end

    end
  end
end
