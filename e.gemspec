# -*- encoding: utf-8 -*-

version = "0.3.6"
Gem::Specification.new do |s|

  s.name = 'e'
  s.version = version
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/espresso/espresso'
  s.summary = 'Espresso Framework %s' % version
  s.description = 'Scalable Framework aimed at Speed and Simplicity'

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'appetite', '~> 0.1.0'
  s.add_dependency 'tilt', '~> 1.3'

  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'specular', '>= 0.1.8'
  s.add_development_dependency 'sonar', '>= 0.1.2'
  s.add_development_dependency 'slim'
  s.add_development_dependency 'haml'

  s.require_paths = ['lib']
  s.files = Dir['**/*'].reject {|e| e =~ /\.(gem|lock)\Z/}
end
