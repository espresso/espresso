module EGeneratorTest__Ctrl
  Spec.new self do
    include GeneratorSpecHelper
    cleanup

    Should 'fail cause not inside Espresso application' do
      output = %x[#{GENERATOR__BIN} g:c Foo]
      check {$?.exitstatus} > 0
      expect(output) =~ /not a generated Espresso application/
    end

    Dir.chdir GENERATOR__DST_ROOT do
      Testing do

        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do
          Context 'creating controllers' do

            Should 'create a controller without route' do
              %x[#{GENERATOR__BIN} g:c Foo]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/foo'
              is(File).directory? dir
              file = dir + '.rb'
              is(File).file? file
              expect(File.read file) =~ /class\s+Foo\s+<\s+E[\n|\s]+def/m
            end

            Should 'create a controller with route' do
              %x[#{GENERATOR__BIN} g:c Bar bar]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/bar'
              is(File).directory? dir
              file = dir + '.rb'
              is(File).file? file
              expect(File.read file) =~ /class\s+Bar\s+<\s+E[\n|\s]+map\s+\Wbar/m
            end

            Should 'create a controller with setups' do
              %x[#{GENERATOR__BIN} g:c Baz engine:Slim format:html]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/baz'
              is(File).directory? dir
              file = dir + '.rb'
              is(File).file? file
              code = File.read(file)
              expect(code) =~ /format\s+\Whtml/m
              expect(code) =~ /engine\s+:Slim/m
            end

            Should 'fail with "already in use"' do
              output = %x[#{GENERATOR__BIN} g:c Baz]
              check {$?.exitstatus} > 0
              expect(output) =~ /already in use/i
            end

          end
        end
      end
    end
    cleanup

  end
end
