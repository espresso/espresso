# encoding: UTF-8

require File.expand_path('../lib/e-version', __FILE__)
Gem::Specification.new do |s|

  s.name = 'e'
  s.version = EVersion::FULL
  s.authors = ['Walter Smith']
  s.email = ['waltee.smith@gmail.com']
  s.homepage = 'https://github.com/espresso/espresso'
  s.summary = 'e-%s' % EVersion::FULL
  s.description = 'Scalable Framework aimed at Speed and Simplicity'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'rack', '~> 1.5'
  s.add_dependency 'tilt', '~> 1.3'
  
  s.add_development_dependency 'bundler'

  s.require_paths = ['lib']
  s.files = Dir['**/{*,.[a-z]*}'].reject {|e| e =~ /\.(gem|lock)\Z/}
  
  s.licenses = ['MIT']
end
