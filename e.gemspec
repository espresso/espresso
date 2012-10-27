# -*- encoding: utf-8 -*-

version = '0.2.4'
Gem::Specification.new do |s|

  s.name = 'e'
  s.version = version
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'https://github.com/slivu/espresso'
  s.summary = 'Espresso Framework %s' % version
  s.description = 'Scalable Framework aimed at Speed and Simplicity'

  s.required_ruby_version = '>= 1.8.7'

  s.add_dependency 'appetite', '~> 0.0.5'
  s.add_dependency 'tilt', '~> 1.3'

  s.add_development_dependency 'rake', '~> 0.9.2'
  s.add_development_dependency 'specular', '~> 0.1.2'
  s.add_development_dependency 'sonar', '~> 0.1'
  s.add_development_dependency 'haml'

  s.require_paths = ['lib']
  s.files = `git ls-files`.split("\n").reject { |f| f =~ /test\/overhead/ }
end
