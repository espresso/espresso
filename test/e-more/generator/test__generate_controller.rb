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

            Should 'create an unmapped controller' do
              %x[#{GENERATOR__BIN} g:c Foo]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/foo'
              is(File).directory? dir
              file = dir + '_controller.rb'
              is(File).file? file
              expect(File.read file) =~ /class\s+Foo\s+<\s+E\n/
            end

            Should 'create a mapped controller' do
              %x[#{GENERATOR__BIN} g:c Bar bar]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/bar'
              is(File).directory? dir
              file = dir + '_controller.rb'
              is(File).file? file
              expect(File.read file) =~ /map\s+\Wbar/m
            end

            Should 'create a controller with setups' do
              %x[#{GENERATOR__BIN} g:c Baz engine:Slim format:html]
              check {$?.exitstatus} == 0
              
              dir = 'base/controllers/baz'
              is(File).directory? dir
              file = dir + '_controller.rb'
              is(File).file? file
              code = File.read(file)
              expect(code) =~ /format\s+\Whtml/m
              expect(code) =~ /engine\s+:Slim/m
            end

            Should 'fail with "constant already in use"' do
              output = %x[#{GENERATOR__BIN} g:c Baz]
              check {$?.exitstatus} > 0
              expect(output) =~ /already in use/i
            end

            Should 'correctly handle namespaces' do
              %x[#{GENERATOR__BIN} g:c A::B::C]
              check {$?.exitstatus} == 0
              dir = 'base/controllers/a/b/c'
              is(File).directory? dir
              file = dir + '_controller.rb'
              is(File).file? file
              code = File.read(file)
              expect(code) =~ /module A/
              expect(code) =~ /module B/
              expect(code) =~ /class C < E/
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

          is(File).file? 'base/views/foo/index.slim'
        end
      end
      cleanup

      Should 'create multiple controllers' do
        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0
        
        Dir.chdir 'App' do
          %x[#{GENERATOR__BIN} g:cs A B C  X::Y::Z  e:Slim]
          check {$?.exitstatus} == 0

          %w[a b c].each do |c|
            dir = "base/controllers/#{c}"
            is(File).directory? dir
            file = dir + "_controller.rb"
            is(File).file? file
            expect {File.read file} =~ /class #{c} < E/i
            is(File).file? "base/views/#{c}/index.slim"
          end

          And 'yet behave well with namespaces' do
            dir = "base/controllers/x/y/z"
            is(File).directory? dir
            file = dir + "_controller.rb"
            is(File).file? file
            is(File).file? "base/views/x/y/z/index.slim"
          end

        end
      end
      cleanup
    end

  end
end
