module EGeneratorTest__Route
  Spec.new self do
    include GeneratorSpecHelper
    cleanup

    Should 'fail cause not inside Espresso application' do
      output = %x[#{GENERATOR__BIN} g:r Foo bar]
      check {$?.exitstatus} > 0
      expect(output) =~ /not a generated Espresso application/
    end

    Dir.chdir GENERATOR__DST_ROOT do
      Testing do

        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0

          Should 'create a basic route' do
            %x[#{GENERATOR__BIN} g:r Foo bar]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/bar.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Foo[\n|\s]+def\s+bar\n/m
          end

          Should 'create a route with args' do
            %x[#{GENERATOR__BIN} g:r Foo argued a, b, c=nil]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/argued.rb'
            is(File).file? file
            expect(File.read file) =~ /class\s+Foo[\n|\s]+def\s+argued\s+a\,\s+b\,\s+c=nil/m
          end
          
          Should 'create a route with setups' do
            %x[#{GENERATOR__BIN} g:r Foo setuped engine:Slim format:html]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/setuped.rb'
            is(File).file? file
            code = File.read file
            expect(code) =~ /format_for\s+:setuped\,\s+\Whtml/
            expect(code) =~ /before\s+:setuped\s+do[\n|\s]+engine\s+:Slim/
            expect(code) =~ /def\s+setuped/m
          end

          Should 'create a route with args and setups' do
            %x[#{GENERATOR__BIN} g:r Foo seturgs a, b, c=nil engine:Slim format:html]
            check {$?.exitstatus} == 0

            file = 'base/controllers/foo/seturgs.rb'
            is(File).file? file
            code = File.read file
            expect(code) =~ /format_for\s+:seturgs\,\s+\Whtml/
            expect(code) =~ /before\s+:seturgs\s+do[\n|\s]+engine\s+:Slim/
            expect(code) =~ /def\s+seturgs\s+a\,\s+b\,\s+c=nil/m
          end

          Should 'inherit engine defined at controller generation' do
            %x[#{GENERATOR__BIN} g:c Pages e:Slim]
            check {$?.exitstatus} == 0

            %x[#{GENERATOR__BIN} g:r Pages edit]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/pages/edit.slim'

            And 'override it when explicitly given' do
              %x[#{GENERATOR__BIN} g:r Pages create e:Haml]
              check {$?.exitstatus} == 0
              is(File).file? 'base/views/pages/create.haml'
            end
          end

        end
      end
      cleanup

      Should 'inherit engine defined at project generation' do
        %x[#{GENERATOR__BIN} g:p App e:Slim]
        check {$?.exitstatus} == 0
        
        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0

          %x[#{GENERATOR__BIN} g:r Foo bar]
          check {$?.exitstatus} == 0

          is(File).file? 'base/views/foo/bar.slim'
        end
      end
      cleanup
    end
  end
end
