module EGeneratorTest__Project
  Spec.new self do
    include GeneratorSpecHelper

    cleanup

    Dir.chdir GENERATOR__DST_ROOT do

      Should 'create a basic project, without any setups' do
        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0
        is(File).directory? 'App'

        Should 'fail cause project already exists' do
          output = %x[#{GENERATOR__BIN} g:p App]
          check {$?.exitstatus} > 0
          expect(output) =~ /already exists/
        end
      end
      cleanup

      [
        ['ActiveRecord', 'activerecord'],
        ['DataMapper', 'data_mapper'],
        ['Sequel', 'sequel']
      ].each do |(o,g)|
        Testing o do

          %x[#{GENERATOR__BIN} g:p App orm:#{o}]
          check {$?.exitstatus} == 0

          Dir.chdir 'App' do
            Ensure 'config.yml updated' do
              expect {
                File.read 'config/config.yml'
              } =~ /orm\W+#{o}/i
            end
            
            Ensure 'Gemfile updated' do
              expect {
                File.read 'Gemfile'
              } =~ /gem\W+#{g}/i
            end

            Ensure 'database.rb updated' do
              expect {
                File.read 'base/database.rb'
              } =~ /#{o}/
            end
          end
        end
        cleanup
      end

      %w[Haml Slim].each do |engine|
        Testing engine do

          %x[#{GENERATOR__BIN} g:p App engine:#{engine} format:#{engine}]
          check {$?.exitstatus} == 0

          Dir.chdir 'App' do
            Ensure 'config.yml updated' do
              cfg = nil
              expect {
                cfg = File.read 'config/config.yml'
              } =~ /engine\W+#{engine}/i
              expect { cfg } =~ /format\W+#{engine}/
            end
            
            Ensure 'Gemfile updated' do
              expect {
                File.read 'Gemfile'
              } =~ /gem\W+#{engine}/im
            end
          end

        end
        cleanup
      end

    end
  end
end
