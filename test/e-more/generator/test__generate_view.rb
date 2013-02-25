module EGeneratorTest__View
  Spec.new self do
    include GeneratorSpecHelper
    cleanup

    Should 'fail cause not inside Espresso application' do
      output = %x[#{GENERATOR__BIN} g:v Foo bar]
      check {$?.exitstatus} > 0
      expect(output) =~ /not a generated Espresso application/
    end

    Dir.chdir GENERATOR__DST_ROOT do
      Testing do

        %x[#{GENERATOR__BIN} g:p App]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do
          Should 'fail with "controller does not exists"' do
            output = %x[#{GENERATOR__BIN} g:v Foo bar]
            check {$?.exitstatus} > 0
            expect(output) =~ /controller does not exists/
          end

          %x[#{GENERATOR__BIN} g:c Foo]
          check {$?.exitstatus} == 0

          Should 'fail with "action does not exists"' do
            output = %x[#{GENERATOR__BIN} g:v Foo bar]
            check {$?.exitstatus} > 0
            expect(output) =~ /action does not exists/
          end

          Ensure 'template automatically created at route generation' do
            %x[#{GENERATOR__BIN} g:r Foo bar]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/foo/bar.erb'
          end

          Should 'correctly convert route to template name' do
            %x[#{GENERATOR__BIN} g:r Foo bar/baz]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/foo/bar__baz.erb'
          end

          Should "use controller name for path to templates" do
            %x[#{GENERATOR__BIN} g:c Bar r:bars_base_addr]
            %x[#{GENERATOR__BIN} g:r Bar some_route]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/bar/some_route.erb'
          end

          Should 'correctly handle namespaces' do
            %x[#{GENERATOR__BIN} g:c A::B::C]
            check {$?.exitstatus} == 0
            dir = 'base/views/a/b/c'
            is(File).directory? dir
            file = dir + '/index.erb'
            is(File).file? file
          end
        end
      end
      cleanup

      Ensure 'extension correctly set' do
        %x[#{GENERATOR__BIN} g:p App e:Sass]
        check {$?.exitstatus} == 0

        Dir.chdir 'App' do
          When 'engine are set at project generation' do
            %x[#{GENERATOR__BIN} g:c ESP]
            check {$?.exitstatus} == 0

            %x[#{GENERATOR__BIN} g:r ESP foo]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/esp/foo.sass'
          end

          When 'engine are set at controller generation' do
            %x[#{GENERATOR__BIN} g:c ESC e:Slim]
            check {$?.exitstatus} == 0

            %x[#{GENERATOR__BIN} g:r ESC foo]
            check {$?.exitstatus} == 0
            is(File).file? 'base/views/esc/foo.slim'

            And 'when engine are set at route generation' do

              %x[#{GENERATOR__BIN} g:r ESC bar e:Haml]
              check {$?.exitstatus} == 0
              is(File).file? 'base/views/esc/bar.haml'
            end
          end

        end
      end
      cleanup
    end

  end
end
