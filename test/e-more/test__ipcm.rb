module EIPCMTest

  Spec.new self do

    Curl = %x[which curl].strip
    fail('"curl" executable not found') unless File.executable?(Curl)

    Thin = %x[which thin].strip
    fail('"thin" executable not found') unless File.executable?(Thin)
    
    def get port, url
      %x[#{Curl} -s localhost:#{port}/#{url.to_s.gsub(/\A\/+/, '')}].strip
    end

    wd = File.expand_path('../ipcm', __FILE__) + '/'
    pids_dir = "#{wd}/tmp/pids/"
    logs_dir = "#{wd}/log/"
    ipcm_dir = "#{wd}/tmp/ipcm/"
    port = 65_000
    servers = 2

    cleanup = proc do
      FileUtils.rm_rf(pids_dir) || fail("Unable to remove #{pids_dir}")
      FileUtils.rm_rf(logs_dir) || fail("Unable to remove #{logs_dir}")
      FileUtils.rm_rf(ipcm_dir) || fail("Unable to remove #{ipcm_dir}")
    end
    start_servers = proc do
      system("#{Thin} -c #{wd} -p #{port} -s #{servers} start")
      sleep 1
    end
    stop_servers = proc do
      system("#{Thin} -c #{wd} -p #{port} -s #{servers} stop &> /dev/null")
    end

    cleanup.call
    stop_servers.call
    start_servers.call

    pids = Dir[pids_dir + '/*.pid'].map { |f| File.read(f).to_i }

    unless pids.size == servers
      stop_servers.call
      cleanup.call
      fail 'Was unable to start app on all specified ports. \
            Make sure %s ports are bind-able' % servers.times.map{ |n| port + n}.inspect
    end

    Context :cache do
      Testing 'main app' do
        body = rand.to_s
        expect { get port, "cache_test/#{body}" } == body

        Ensure 'cached body returned' do
          expect { get port, "cache_test/#{rand}" } == body
        end
      end

      1.upto(servers-1).each do |n|
        p = port + n
        Testing "app on port #{p}" do
          body = rand.to_s
          expect { get p, "cache_test/#{body}" } == body

          Ensure 'cached body returned' do
            expect { get p, "cache_test/#{rand}" } == body
          end
        end
      end

      Testing 'cache cleaner' do
        body = rand.to_s
        expect { get port, "cache_test/#{body}/?clear_cache=true" } == body

        Ensure 'cache cleaned also on other apps' do
          1.upto(servers-1).each do |n|
            p = port + n
            Testing "app on port #{p}" do
              body = rand.to_s
              expect { get p, "cache_test/#{body}" } == body
            end
          end
        end
      end
    end

    Context :compiler do
      Testing 'main app' do
        body = rand.to_s
        expect { get port, "compiler_test/#{body}" } == body

        Ensure 'compiled body returned' do
          expect { get port, "compiler_test/#{rand}" } == body
        end
      end

      1.upto(servers-1).each do |n|
        p = port + n
        Testing "app on port #{p}" do
          body = rand.to_s
          expect { get p, "compiler_test/#{body}" } == body

          Ensure 'compiled body returned' do
            expect { get p, "compiler_test/#{rand}" } == body
          end
        end
      end

      Testing 'complier cleaner' do
        body = rand.to_s
        expect { get port, "compiler_test/#{body}/?clear_compiler=true" } == body

        Ensure 'compiler cleaned also on other apps' do
          1.upto(servers-1).each do |n|
            p = port + n
            Testing "app on port #{p}" do
              body = rand.to_s
              expect { get p, "compiler_test/#{body}" } == body
            end
          end
        end
      end
    end

    stop_servers.call
    cleanup.call
  end
end
