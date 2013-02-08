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

        end
      end
      cleanup
    end
  end
end
