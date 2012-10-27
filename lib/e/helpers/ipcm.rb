class EApp

  def ipcm_trigger *args
    if pids_reader
      pids = pids_reader.call rescue nil
      if pids.is_a?(Array) 
        pids.map {|p| p.to_i}.reject {|p| p < 2 || p == Process.pid }.each do |pid|
          begin
            File.open('%s/%s.%s-%s' % [ipcm_tmpdir, pid, args.hash, Time.now.to_f], 'w') do |f|
              f << Marshal.dump(args)
            end
            Process.kill ipcm_signal, pid
          rescue => e
            warn "was unable to perform IPCM operation because of error: %s" % ::CGI.escapeHTML(e.message)
          end
        end
      else
        warn "pids_reader should return an array of pids. Exiting IPCM..."
      end
    end
  end

  def ipcm_tmpdir path = nil
    return @ipcm_tmpdir if @ipcm_tmpdir
    if path
      @ipcm_tmpdir = ((path =~ /\A\// ? path : root + path) + '/').freeze
    else
      @ipcm_tmpdir = (root + 'tmp/ipcm/').freeze
    end
    FileUtils.mkdir_p @ipcm_tmpdir
    @ipcm_tmpdir
  end

  def ipcm_signal signal = nil
    return @ipcm_signal if @ipcm_signal
    @ipcm_signal = signal.to_s if signal
    @ipcm_signal ||= 'ALRM'
  end

  def register_ipcm_signal
    Signal.trap ipcm_signal do
      Dir[ipcm_tmpdir + '%s.*' % Process.pid].each do |file|
        unless (setup = Marshal.restore(File.read(file)) rescue nil).is_a?(Array)
          warn "Was unable to process \"%s\" cache file, skipping cache cleaning" % file
        end
        File.unlink file
        meth = setup.shift
        [ :clear_cache,
          :clear_cache_like,
          :clear_compiler,
          :clear_compiler_like,
        ].include?(meth) && self.send(meth, *setup)
      end
    end
  end

end
