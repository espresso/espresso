require 'tempfile'

wd = File.expand_path('..', __FILE__) << '/'
pids = {:app => [], :bench => []}
files = {}
results = {}

{
  'espresso' => 60082,
}.each_pair do |app, port|
  if pid = Process.spawn("ruby #{wd + app}-app.rb #{port}")
    puts 'Testing %s app ... ' % app
    sleep 2
    status = %x[curl -s -o /dev/null -w "%{http_code}" 127.0.0.1:#{port}].strip.to_i
    unless status == 200
      puts "=== Failed to start #{app} app ===\n"
      exit 1
    end
    pids[:app] << pid
    cmd = "ab -n1000 -c100 -q 127.0.0.1:#{port}/|grep 'Requests per second'"
    files[app] = Tempfile.new(app)
    pids[:bench] << Process.spawn(cmd, :out => files[app].path)
  end
end

pids[:bench].each { |p| Process.wait(p) }
files.each_pair do |app, file|
  file.rewind
  result = file.read.sub("Requests per second", "").strip
  results[app] = result.sub(/.*\:\s+(.*)\s+\[.*/, '\1').to_i
end
pids[:app].each { |p| Process.kill(9, p) }

rpsout = lambda do |overhead, ms|
  out = (1000 / (overhead + ms)).to_i.to_s
  "  " << out << (" " * ((6 + ms.to_s.size) - out.size) )
end

puts
puts "-"*3
puts (" "*12) + "Speed  Overhead  1ms-app  5ms-app  10ms-app  20ms-app  50ms-app  100ms-app"
results.each_pair do |app, rps|
  overhead = 1000.to_f / rps.to_f
  overhead_to_s = '%.2fms' % overhead
  output = "%s  %s  %s" % [
      (" "*(10-app.size)) + app,
      rps.to_s + " "*(5-rps.to_s.size),
      overhead_to_s + (" "*(8-overhead_to_s.size))
  ]
  [1,5,10,20,50,100].each do |ao|
    output << rpsout.call(overhead, ao)
  end
  puts output
end
puts "-"*3
puts
