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

            file = 'base/models/foo.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Foo\n/
          end

          Should 'generate a model of given ORM' do
          
            %x[#{GENERATOR__BIN} g:m Bar o:ActiveRecord]
            check {$?.exitstatus} == 0

            file = 'base/models/bar.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Bar\s<\s+ActiveRecord/
          end

          Should 'correctly handle namespaces' do
            %x[#{GENERATOR__BIN} g:m A::B::C]
            check {$?.exitstatus} == 0

            file = 'base/models/a/b/c.rb'
            is(File).file? file
            code = File.read(file)
            expect(code) =~ /module A/
            expect(code) =~ /module B/
            expect(code) =~ /class C/
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

          file = 'base/models/foo.rb'
          is(File).file? file
          expect(File.read file) =~ /class\s+Foo\n\s+include\s+DataMapper/m
        end
      end
      cleanup

      Should 'create multiple models' do
        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0
        
        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:ms A B C  X::Y::Z  o:ar]
          check {$?.exitstatus} == 0

          %w[a b c].each do |c|
            file = "base/models/#{c}.rb"
            is(File).file? file
            expect {File.read file} =~ /class #{c} < ActiveRecord/i
          end

          And 'yet behave well with namespaces' do
            file = "base/models/x/y/z.rb"
            is(File).file? file
            expect {File.read file} =~ /class Z < ActiveRecord/i
          end
        end
      end
      cleanup
    end
  end
end
