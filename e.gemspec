# encoding: UTF-8

version = "0.4.3"
Gem::Specification.new do |s|

  s.name = 'e'
  s.version = version
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/espresso/espresso'
  s.summary = 'e-%s' % version
  s.description = 'Scalable Framework aimed at Speed and Simplicity'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'rack', '~> 1.5'
  s.add_dependency 'tilt', '~> 1.3'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  
  s.licenses = ['MIT']
end
