## a temp script to fix links in docs
files = Dir["**/**.md"]

files.each do |f|
  c = File.read(f).force_encoding('utf-8')
  replaced = c.split("\n").map do |line|
    line.gsub!("https://github.com/slivu/espresso/blob/master/", "https://github.com/slivu/espresso/blob/master/docs/")
    line
  end.join("\n")
  File.open(f, 'w') do |fw|
    fw.puts replaced
  end
end