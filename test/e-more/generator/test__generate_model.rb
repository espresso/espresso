module EGeneratorTest__Model
  Spec.new self do
    include GeneratorSpecHelper
    cleanup

    Should 'fail cause not inside Espresso application' do
      output = %x[#{GENERATOR__BIN} g:m Foo]
      check {$?.exitstatus} > 0
      expect(output) =~ /not a generated Espresso application/
    end

    Dir.chdir GENERATOR__DST_ROOT do
      Testing do

        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do

          Should 'generate a plain class cause no setups given' do
            %x[#{GENERATOR__BIN} g:m Foo]
            check {$?.exitstatus} == 0

            dir = 'base/models/foo'
            is(File).directory? dir
            file = dir + '.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Foo\n/
          end

          Should 'generate a model of given ORM' do
          
            %x[#{GENERATOR__BIN} g:m Bar ActiveRecord]
            check {$?.exitstatus} == 0

            dir = 'base/models/bar'
            is(File).directory? dir
            file = dir + '.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Bar\s<\s+ActiveRecord/
            
          end

        end
      end
      cleanup

      Should 'use ORM defined at project generation' do
        %x[#{GENERATOR__BIN} g:p App orm:DataMapper]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do

          %x[#{GENERATOR__BIN} g:m Foo]
          check {$?.exitstatus} == 0

          dir = 'base/models/foo'
          is(File).directory? dir
          file = dir + '.rb'
          is(File).file? file
          expect(File.read file) =~ /class\s+Foo\n\s+include\s+DataMapper/m
        end
      end
      cleanup
    end
  end
end
